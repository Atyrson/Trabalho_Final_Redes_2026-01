#!/bin/bash
#
# Configuração do Servidor DHCP no Roteador R2 (192.168.0.1)
#
set -e

echo "=== [R2] Configuração Automatizada do Servidor DHCP ==="
echo

# 1. Instalação do dnsmasq
if ! command -v dnsmasq &> /dev/null; then
    echo "[R2] Instalando o dnsmasq..."
    sudo apt update && sudo apt install -y dnsmasq
fi

# 2. Escrita do arquivo de configuração (/etc/dnsmasq.conf)
echo "[R2] Gerando arquivo /etc/dnsmasq.conf para DHCP..."
sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
# Desativa completamente o servidor DNS local no R2 (libera a porta 53)
port=0

# Define a interface de escuta para a LAN 2 (ajuste se a sua interface não for eth1)
interface=enp0s31f6
listen-address=192.168.0.1

# Escopo de IPs dinâmicos para os clientes X e Y
dhcp-range=192.168.0.10,192.168.0.50,255.255.255.0,12h

# Opção 3: Define o R2 (192.168.0.1) como o gateway padrão deles
dhcp-option=3,192.168.0.1

# Opção 6: Aponta obrigatoriamente para o Host S (172.16.0.2) como servidor DNS
dhcp-option=6,172.16.0.2

# Opção 15: Define o sufixo de domínio da rede local
dhcp-option=15,miniiptv.lan
EOF

# 3. Inicialização do serviço
echo "[R2] Reiniciando o serviço dnsmasq..."
sudo systemctl restart dnsmasq

echo
echo "=== [SUCESSO] R2 configurado como Servidor DHCP! ==="
sudo systemctl status dnsmasq --no-pager
