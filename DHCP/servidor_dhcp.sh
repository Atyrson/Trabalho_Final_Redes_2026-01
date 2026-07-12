#!/bin/bash
#
# Configuração do Servidor DHCP - Empresa PipeVendas
# Fundamentos de Redes de Computadores - 2026.1
#
# Roda no ROTEADOR R2 (IP fixo 192.168.0.1 na perna da LAN dos clientes).
# Distribui IPs dinâmicos para as estações X e Y da LAN #2, entregando
# junto o gateway (o próprio R2) e o servidor DNS do grupo (host S).

set -e

# Configurações da empresa ==========================
EMPRESA="PipeVendas"
DOMINIO="pipevendas.com.br"

# IPs da infraestrutura (topologia real do projeto) =
# O DHCP roda no R2 e serve a LAN #2 (clientes X e Y).
# O gateway anunciado é o próprio R2; o DNS fica no host S
# (LAN #1), alcançado pelos clientes via rota default R2 -> R1 -> S.
IP_ROTEADOR="192.168.0.1"      # gateway = R2 (esta máquina, perna da LAN)
IP_DNS="172.16.0.2"            # servidor DNS do grupo (host S, LAN #1)
IP_DHCP="192.168.0.1"          # este servidor (R2)
REDE="192.168.0.0"
MASCARA="255.255.255.0"
BROADCAST="192.168.0.255"

# Faixa de IPs ofertada aos clientes ================
RANGE_INI="192.168.0.100"
RANGE_FIM="192.168.0.200"

# Interface de rede onde o DHCP vai escutar ==========
# AJUSTE para a interface do R2 voltada à LAN dos clientes (veja com: ip a).
# É a MESMA interface que o NetworkConfig/roteador-r2/r2lan.sh configurou
# com 192.168.0.1/24.
INTERFACE="enp0s8"

# Etapa 1 ===========================================
echo "========= Instalando servidor DHCP para $EMPRESA... ========="
sudo apt update
sudo apt install -y isc-dhcp-server

# Etapa 2 ===========================================
# OBS.: o roteiro antigo cita 'dhcp3-server' e '/etc/dhcpd.conf'.
# Nas versões atuais do Ubuntu/Debian o pacote é 'isc-dhcp-server'
# e o arquivo de configuração fica em '/etc/dhcp/dhcpd.conf'.
echo "Escrevendo /etc/dhcp/dhcpd.conf..."

sudo tee /etc/dhcp/dhcpd.conf > /dev/null <<EOF
# ===== Configuração DHCP - $EMPRESA =====

# Tempos de lease (em segundos)
default-lease-time 600;     # 10 min
max-lease-time 7200;        # 2 horas

# Este servidor é a autoridade oficial de DHCP nesta rede.
# Corrige clientes que pedem endereços incoerentes (envia DHCPNAK).
authoritative;

# Opções globais entregues a todos os clientes
option subnet-mask $MASCARA;
option broadcast-address $BROADCAST;
option routers $IP_ROTEADOR;
option domain-name-servers $IP_DNS;
option domain-name "$DOMINIO";

# Sub-rede da intranet $REDE/24
subnet $REDE netmask $MASCARA {
    range $RANGE_INI $RANGE_FIM;
    option routers $IP_ROTEADOR;
    option domain-name-servers $IP_DNS;
    option domain-name "$DOMINIO";
}

# ---------------------------------------------------------
# RESERVA POR MAC (responde a Questão 2 do roteiro)
# Uma estação cujo MAC seja conhecido recebe SEMPRE o mesmo IP.
# Troque o MAC abaixo pelo da estação cliente real (ip a no cliente).
# ---------------------------------------------------------
host estacao-fixa {
    hardware ethernet 08:00:27:aa:bb:cc;
    fixed-address 192.168.0.50;
    option host-name "estacao1";
}
EOF

# Etapa 3 ===========================================
echo "Definindo a interface de escuta ($INTERFACE)..."
sudo sed -i "s/^INTERFACESv4=.*/INTERFACESv4=\"$INTERFACE\"/" /etc/default/isc-dhcp-server

# Etapa 4 ===========================================
echo "Validando a sintaxe do dhcpd.conf..."
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf

# Etapa 5 ===========================================
echo "Reiniciando o servidor DHCP..."
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

# Etapa 6 ===========================================
echo ""
echo "=== CONFIGURAÇÃO CONCLUÍDA ==="
echo "Servidor DHCP: $IP_DHCP  (interface $INTERFACE)"
echo "Faixa ofertada: $RANGE_INI - $RANGE_FIM"
echo "Gateway: $IP_ROTEADOR | DNS: $IP_DNS | Domínio: $DOMINIO"
echo ""
echo "Ver status:        sudo systemctl status isc-dhcp-server"
echo "Ver leases ativos: cat /var/lib/dhcp/dhcpd.leases"
echo "Rodar em modo debug (mostra o diálogo na tela):"
echo "   sudo systemctl stop isc-dhcp-server"
echo "   sudo /usr/sbin/dhcpd -d -f $INTERFACE"
echo ""
echo "Concluído."
