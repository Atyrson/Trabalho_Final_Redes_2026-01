#!/bin/bash
#
# s_dns_v2.sh - Configuração DNS Otimizada e Segura para o Host S
#
set -e

echo "=== [Host S] Configuração de DNS à Prova de Erros ==="
echo

# 1. Destravar o gerenciador de pacotes APT (Prevenção de Erros)
echo "[1/6] Verificando e liberando possíveis travas do APT..."
sudo killall -9 apt apt-get 2>/dev/null || true
sudo rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* 2>/dev/null || true
sudo dpkg --configure -a 2>/dev/null || true

# 2. Instalação robusta do dnsmasq completo
echo "[2/6] Verificando instalação do servidor dnsmasq..."
if ! dpkg -l | grep -q "^ii  dnsmasq "; then
    echo "    -> Instalando o pacote completo do dnsmasq..."
    sudo apt update && sudo apt install -y dnsmasq
else
    echo "    -> dnsmasq já está corretamente instalado."
fi

# 3. Resolução do conflito na porta 53 (systemd-resolved)
echo "[3/6] Desativando o systemd-resolved para liberar a porta 53..."
sudo systemctl stop systemd-resolved 2>/dev/null || true
sudo systemctl disable systemd-resolved 2>/dev/null || true

# 4. Configuração do arquivo do Sistema (/etc/resolv.conf)
# NOTA: Este arquivo do OS deve conter APENAS o nameserver local.
echo "[4/6] Configurando o arquivo /etc/resolv.conf do sistema operacional..."
sudo rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf > /dev/null

# 5. Mapeamento de IPs Estáticos locais (/etc/hosts)
echo "[5/6] Configurando mapeamento de nomes internos no /etc/hosts..."
sudo sed -i '/miniiptv.lan/d' /etc/hosts
sudo tee -a /etc/hosts > /dev/null <<EOF
172.16.0.2      s.miniiptv.lan s
172.16.0.1      r1.miniiptv.lan r1
192.168.0.1     r2.miniiptv.lan r2
EOF

# 6. Configuração limpa do serviço (/etc/dnsmasq.conf)
# NOTA: Sem a diretiva problemática 'local-service=0'.
echo "[6/6] Gerando o arquivo de configuração /etc/dnsmasq.conf..."
sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
# Escuta na interface local e explicitamente no IP da LAN 1 do Host S
listen-address=127.0.0.1,172.16.0.2
bind-interfaces

# Configuração do domínio local da intranet
domain=miniiptv.lan
expand-hosts

# Redirecionamento para a Internet (Upstream DNS)
# O Host S consulta estes servidores se não souber resolver localmente
no-resolv
server=8.8.8.8
server=1.1.1.1

# Garante que este host não tente ofertar IPs via DHCP
no-dhcp-interface=lo,eth0,eth1,ppp0
EOF

# 7. Reinicialização e Validação do Serviço
echo "--------------------------------------------------"
echo "Reiniciando e ativando o serviço dnsmasq..."
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

echo
echo "=== [SUCESSO] O Servidor DNS no Host S está pronto para uso! ==="
echo "--------------------------------------------------"
sudo systemctl status dnsmasq --no-pager

