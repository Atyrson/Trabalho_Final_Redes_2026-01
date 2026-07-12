#!/bin/bash

set -e

# ============================================================
# Servidor DNS (BIND9) do grupo — roda no HOST S (LAN #1).
# Fundamentos de Redes de Computadores - 2026.1
#
# Topologia real do projeto:
#   LAN #1 (S <-> R1) .....: 172.16.0.0/16   S=172.16.0.2  R1=172.16.0.1
#   WAN/core (R1 <-> R2) ..: 10.0.0.0/24     R1=10.0.0.1   R2=10.0.0.2
#   LAN #2 (clientes X/Y) .: 192.168.0.0/24  R2=192.168.0.1 (gateway)
#
#   DNS + SMTP rodam no host S; WWW/API Gateway no R1; DHCP no R2.
# ============================================================

# Configurações da empresa
EMPRESA="PipeVendas"
DOMINIO="pipevendas.com.br"

# IPs dos servidores conforme a topologia real
IP_DNS="172.16.0.2"        # host S (este servidor, DNS + SMTP)
IP_SMTP="172.16.0.2"       # host S (mesmo IP do DNS)
IP_ROTEADOR="172.16.0.1"   # R1 (gateway da LAN #1 / API Gateway / WWW)
IP_WWW="172.16.0.1"        # R1 (Apache proxy reverso = www)
IP_R2="192.168.0.1"        # R2 (gateway da LAN #2 e servidor DHCP)
IP_DHCP="192.168.0.1"      # R2 (roda o serviço DHCP)

DNS_IP="$IP_DNS"

# Etapa 1 ==========================================
echo "========= Instalando BIND para $EMPRESA... ========="

sudo apt update
sudo apt install -y bind9 bind9utils dnsutils

# Etapa 2 ==========================================
echo "Configurando resolver..."

sudo tee /etc/resolv.conf > /dev/null <<EOF
domain $DOMINIO
search $DOMINIO
nameserver $DNS_IP
EOF

# Etapa 3 ==========================================
echo "Configurando zonas do $DOMINIO..."

sudo tee /etc/bind/named.conf.local > /dev/null <<EOF
// Zona direta do domínio $DOMINIO
zone "$DOMINIO" {
    type master;
    file "/etc/bind/db.$DOMINIO";
    allow-update { $IP_DHCP; };  // DHCP (R2) pode atualizar via DDNS
};

// Zona reversa dos SERVIDORES (LAN #1 172.16.0.0/16)
zone "16.172.in-addr.arpa" {
    type master;
    file "/etc/bind/db.16.172";
    allow-update { $IP_DHCP; };
};

// Zona reversa dos CLIENTES (LAN #2 192.168.0.0/24)
zone "0.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.0.168.192";
    allow-update { $IP_DHCP; };  // DHCP (R2) pode atualizar via DDNS
};

EOF

# Etapa 4 ==========================================
echo "Criando zona direta para $DOMINIO..."

sudo tee /etc/bind/db.$DOMINIO > /dev/null <<EOF
\$TTL 86400

@ IN SOA ns1.$DOMINIO. admin.$DOMINIO. (
    2026071101  ; Serial (YYYYMMDDNN)
    21600       ; Refresh (6 horas)
    1800        ; Retry (30 minutos)
    604800      ; Expire (1 semana)
    86400       ; Minimum TTL (24 horas)
)

; Servidores DNS
@ IN NS ns1.$DOMINIO.
@ IN NS ns2.$DOMINIO.

; Servidor de email (MX)
@ IN MX 10 mail.$DOMINIO.

; Registros A (mapeamento nome → IP) - SOMENTE SERVIDORES FIXOS
localhost IN A 127.0.0.1

; Servidores da infraestrutura (IPs fixos)
ns1     IN A $IP_DNS          ; Servidor DNS principal (host S)
ns2     IN A $IP_DNS          ; Servidor DNS secundário (mesmo IP no lab)
router  IN A $IP_ROTEADOR     ; R1 - Gateway/Roteador da LAN #1
r1      IN A $IP_ROTEADOR     ; R1 (alias)
r2      IN A $IP_R2           ; R2 - Gateway da LAN #2 / DHCP
www     IN A $IP_WWW          ; Servidor Web / API Gateway (R1)
dhcp    IN A $IP_DHCP         ; Servidor DHCP (R2)
mail    IN A $IP_SMTP         ; Servidor de email (host S)

; Aliases (CNAME) para serviços
smtp    IN CNAME mail.$DOMINIO.
pop3    IN CNAME mail.$DOMINIO.
imap    IN CNAME mail.$DOMINIO.

; ===================================================
; NOTA: Os registros para as estações clientes (X/Y)
; serão adicionados DINAMICAMENTE pelo DHCP via DDNS
; ===================================================

EOF

# Etapa 5 ==========================================
echo "Criando zona reversa dos SERVIDORES (172.16.0.0/16)..."

# Para 172.16.0.0/16 os nomes PTR são "<host>.<terceiro-octeto>"
# Ex.: 172.16.0.2 -> "2.0", 172.16.0.1 -> "1.0"
sudo tee /etc/bind/db.16.172 > /dev/null <<EOF
\$TTL 86400

@ IN SOA ns1.$DOMINIO. admin.$DOMINIO. (
    2026071101  ; Serial (YYYYMMDDNN)
    21600       ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Minimum TTL
)

@ IN NS ns1.$DOMINIO.
@ IN NS ns2.$DOMINIO.

; Registros PTR para SERVIDORES da LAN #1 (IPs fixos)
2.0 IN PTR ns1.$DOMINIO.     ; 172.16.0.2 (host S / DNS / mail)
2.0 IN PTR mail.$DOMINIO.    ; 172.16.0.2
1.0 IN PTR router.$DOMINIO.  ; 172.16.0.1 (R1 / www)

EOF

echo "Criando zona reversa dos CLIENTES (192.168.0.0/24)..."

sudo tee /etc/bind/db.0.168.192 > /dev/null <<EOF
\$TTL 86400

@ IN SOA ns1.$DOMINIO. admin.$DOMINIO. (
    2026071101  ; Serial (YYYYMMDDNN)
    21600       ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Minimum TTL
)

@ IN NS ns1.$DOMINIO.
@ IN NS ns2.$DOMINIO.

; Registro PTR fixo do gateway da LAN #2
1 IN PTR r2.$DOMINIO.   ; 192.168.0.1 (R2 / gateway / DHCP)

; ===================================================
; NOTA: Os registros PTR para as estações clientes (X/Y)
; serão adicionados DINAMICAMENTE pelo DHCP via DDNS
; ===================================================

EOF

# Etapa 6 ==========================================
echo "Configurando permissões dos arquivos de zona (updates dinâmicos)..."

sudo chown bind:bind /etc/bind/db.$DOMINIO
sudo chown bind:bind /etc/bind/db.16.172
sudo chown bind:bind /etc/bind/db.0.168.192

# Etapa 7 ==========================================
echo "Validando configuração..."

sudo named-checkconf
sudo named-checkzone $DOMINIO /etc/bind/db.$DOMINIO
sudo named-checkzone 16.172.in-addr.arpa /etc/bind/db.16.172
sudo named-checkzone 0.168.192.in-addr.arpa /etc/bind/db.0.168.192

# Etapa 8 ==========================================
echo "Reiniciando BIND..."

sudo systemctl restart bind9
sudo systemctl enable bind9

# Etapa 9 ==========================================
echo ""
echo "=== CONFIGURAÇÃO CONCLUÍDA ==="
echo ""
echo "Domínio configurado: $DOMINIO"
echo "Servidor DNS (host S): $DNS_IP"
echo ""
echo "=== REGISTROS DNS CONFIGURADOS (SERVIDORES FIXOS) ==="
echo ""
echo "  ns1.$DOMINIO / mail.$DOMINIO → $IP_DNS   (host S)"
echo "  router.$DOMINIO / www.$DOMINIO → $IP_ROTEADOR (R1)"
echo "  r2.$DOMINIO / dhcp.$DOMINIO   → $IP_R2   (R2)"
echo ""
echo "=== INTEGRAÇÃO COM DHCP (DDNS) — DHCP roda no R2 ($IP_DHCP) ==="
echo ""
echo "Para registro automático das estações, no R2 (/etc/dhcp/dhcpd.conf):"
echo ""
echo "   option domain-name \"$DOMINIO\";"
echo "   option domain-name-servers $IP_DNS;"
echo "   ddns-update-style interim;"
echo "   ddns-updates on;"
echo ""
echo "   zone $DOMINIO. {"
echo "       primary $IP_DNS;"
echo "       key rndc-key;"
echo "   }"
echo "   zone 0.168.192.in-addr.arpa. {"
echo "       primary $IP_DNS;"
echo "       key rndc-key;"
echo "   }"
echo ""
echo "No host S, gere a chave e inclua no BIND:"
echo "   sudo rndc-confgen -a -b 256"
echo "   include \"/etc/bind/rndc.key\";  # em /etc/bind/named.conf"
echo ""
echo "=== TESTES ==="
echo ""
echo "Consulta direta:"
echo "  host www.$DOMINIO      # espera $IP_WWW"
echo "  host mail.$DOMINIO     # espera $IP_SMTP"
echo "  host r2.$DOMINIO       # espera $IP_R2"
echo ""
echo "Consulta reversa:"
echo "  host $IP_DNS           # espera ns1/mail.$DOMINIO"
echo "  host $IP_ROTEADOR      # espera router/www.$DOMINIO"
echo "  host $IP_R2            # espera r2.$DOMINIO"
echo ""
echo "Status do serviço:"
echo "  sudo systemctl status bind9"
echo ""
echo "Monitorar atualizações DDNS:"
echo "  sudo tail -f /var/log/syslog | grep -i ddns"
echo ""
echo "Concluído."
