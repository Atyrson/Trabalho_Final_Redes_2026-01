#!/bin/bash

set -e

echo "[R2] Desativando NetworkManager ===================="

sudo systemctl stop NetworkManager || true

sudo ip addr flush dev eth0

echo "[R2] LAN ===================="

sudo ip addr add 192.168.2.1/24 dev eth0

sudo ip link set eth0 up

sudo ip link set eth0 multicast on

echo "[R2] Ativando roteamento ===================="

echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

echo "[R2] Rotas ===================="

sudo ip route add 172.16.0.0/24 via 10.0.0.1 dev ppp0 || true

echo "[R2] Configurando multicast ===================="

sudo pkill smcrouted || true

sudo smcrouted

sleep 2

sudo smcroute -a ppp0 172.16.0.1 239.1.1.1 eth0

echo
echo "Tabela multicast ===================="

ip mroute