#!/bin/bash

set -e

echo "[R1] Desativando NetworkManager"

sudo systemctl stop NetworkManager || true

echo "[R1] Limpando"

sudo ip addr flush dev eth0

echo "[R1] LAN"

sudo ip addr add 172.16.0.2/24 dev eth0

sudo ip link set eth0 up

sudo ip link set eth0 multicast on

echo "[R1] Ativando roteamento"

echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

echo "[R1] Rotas"

sudo ip route add 192.168.2.0/24 via 10.0.0.2 dev ppp0 || true

sudo ip route add 224.0.0.0/4 dev ppp0 || true

echo
echo "Suba PPP:"
echo "sudo /usr/sbin/pppd"

echo
ip route