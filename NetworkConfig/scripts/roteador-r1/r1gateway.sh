#!/bin/bash

# Ativa a interface da LAN
# ip link set enx00e04c6822c0 up
# ip addr flush dev enx00e04c6822c0
# ip addr add 172.16.0.1/24 dev enx00e04c6822c0

# Ativa encaminhamento de pacotes
sysctl -w net.ipv4.ip_forward=1

# Remove rota antiga, se existir
ip route del 192.168.0.0/24 2>/dev/null

# Adiciona rota para a rede atrás do R2
ip route add 192.168.0.0/24 via 10.0.0.2 dev ppp0

echo "Configuração concluída de gateway."
