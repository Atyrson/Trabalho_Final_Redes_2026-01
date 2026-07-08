#!/bin/bash

set -e

sudo systemctl stop NetworkManager || true

sudo ip addr flush dev eth0

sudo ip addr add 172.16.0.1/24 dev eth0

sudo ip link set eth0 up

sudo ip link set eth0 multicast on

sudo ip route replace default via 172.16.0.2

echo
ip addr show eth0

echo
echo 'cvlc video.mp4 --sout="#rtp{dst=239.1.1.1,port=5004,mux=ts}"'