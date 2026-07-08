#!/bin/bash

set -e

echo "[S] Desativando NetworkManager ===================="

sudo systemctl stop NetworkManager || true

echo "[S] Limpando configuração ===================="

sudo ip addr flush dev eth0

echo "[S] Configurando rede ===================="

sudo ip addr add 172.16.0.1/24 dev eth0

sudo ip link set eth0 up

sudo ip link set eth0 multicast on

echo "[S] Gateway ===================="

# sudo ip route replace default via 172.16.0.2
sudo ip route add default via 172.16.0.2 || true

echo
echo "Verificar: ===================="
ip a

echo
echo "Transmitir vídeo:"
echo 'cvlc video.mp4 --sout="#rtp{dst=239.1.1.1,port=5004,mux=ts}"'