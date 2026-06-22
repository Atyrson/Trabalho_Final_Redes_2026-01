#!/bin/bash

set -e

sudo systemctl stop NetworkManager || true

sudo ip addr flush dev eth0

sudo ip addr add 192.168.2.10/24 dev eth0

sudo ip link set eth0 up

sudo ip link set eth0 multicast on

sudo ip route add default via 192.168.2.1 || true

sudo ip route add 224.0.0.0/4 dev eth0 || true

sudo ip maddr add 239.1.1.1 dev eth0 || true

echo
echo "Rede"

ip a

echo
echo "Receber vídeo"

echo "vlc udp://@239.1.1.1:5004"