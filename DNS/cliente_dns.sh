#!/bin/bash

# Cliente com IP estático: aponta o resolver para o DNS do grupo (host S).
# Em clientes que pegam IP via DHCP, o nameserver já vem automaticamente.
tee /etc/resolv.conf > /dev/null <<EOF
domain pipevendas.com.br
search pipevendas.com.br
nameserver 172.16.0.2
EOF