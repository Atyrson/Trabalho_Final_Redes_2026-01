#!/bin/bash
#
# r2_rotas_fix.sh - Restaura a interface física e corrige o gateway do R2
#
set -e

INTERFACE_LAN="enp0s31f6"

echo "=== [R2] Restaurando Configurações de Interface e Roteamento ==="
echo

# 1. Ativar e configurar a interface física LAN #2
echo "[1/4] Configurando IP estático 192.168.0.1 na interface $INTERFACE_LAN..."
sudo ip addr flush dev $INTERFACE_LAN 2>/dev/null || true
sudo ip addr add 192.168.0.1/24 dev $INTERFACE_LAN
sudo ip link set dev $INTERFACE_LAN up

# 2. Corrigir a rota padrão (remover a genérica e adicionar a correta via 10.0.0.1)
echo "[2/4] Ajustando rota padrão para apontar via 10.0.0.1..."
# Remove qualquer rota padrão genérica anterior para evitar conflito
sudo ip route del default dev ppp0 2>/dev/null || true
sudo ip route del default 2>/dev/null || true

# Adiciona a rota padrão exata apontando para o IP do R1 na WAN
sudo ip route add default via 10.0.0.1 dev ppp0

# 3. Garantir que o encaminhamento de pacotes está ativo no Kernel
echo "[3/4] Forçando ativação do IP Forwarding no R2..."
sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null

# 4. Reiniciar o serviço de DHCP (dnsmasq) para atualizar a escuta na rede
if systemctl is-active --quiet dnsmasq; then
    echo "[4/4] Reiniciando dnsmasq para validar o DHCP..."
    sudo systemctl restart dnsmasq
fi

echo
echo "=== [SUCESSO] Configuração de rotas do R2 restaurada! ==="
echo "--------------------------------------------------------"
echo "Tabela de rotas atual:"
ip route
