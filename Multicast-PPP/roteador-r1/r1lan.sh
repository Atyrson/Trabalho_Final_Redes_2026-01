#!/bin/bash
#
# Configuração da interface de rede do R1 voltada para a LAN #1 (host S)
#
set -e

list_net_interfaces() {
    ip -o link show \
        | awk -F': ' '{print $2}' \
        | grep -Ev '^(lo|ppp[0-9]*|docker|veth|br-|virbr)' \
        | sort
}

escolher_item() {
    local titulo="$1"
    local itens="$2"
    local arr=()
    while IFS= read -r linha; do
        [ -n "$linha" ] && arr+=("$linha")
    done <<< "$itens"

    if [ ${#arr[@]} -eq 0 ]; then
        echo "[ERRO] Nenhuma interface encontrada." >&2
        exit 1
    fi

    echo "$titulo" >&2
    select escolha in "${arr[@]}"; do
        if [ -n "$escolha" ]; then
            echo "$escolha"
            return 0
        else
            echo "Opção inválida, tente novamente." >&2
        fi
    done
}

echo "=== [R1] Configuração da interface LAN #1 (rede do host S) ==="
echo

IF_LAN=$(escolher_item "Selecione a interface conectada à LAN #1:" "$(list_net_interfaces)")

read -rp "Endereço IP a ser configurado nessa interface [padrão 172.16.0.1/24]: " IP_LAN
IP_LAN=${IP_LAN:-172.16.0.1/24}

echo
echo "Resumo:"
echo "  Interface .....: $IF_LAN"
echo "  Endereço IP ...: $IP_LAN"
read -rp "Confirma? [s/N] " confirma
if [[ ! "$confirma" =~ ^[sS]$ ]]; then
    echo "Abortado pelo usuário."
    exit 1
fi

echo "[R1] Desativando NetworkManager"
sudo systemctl stop NetworkManager || true

echo "[R1] Limpando endereços de $IF_LAN"
sudo ip addr flush dev "$IF_LAN"

echo "[R1] Configurando LAN #1"
sudo ip addr add "$IP_LAN" dev "$IF_LAN"
sudo ip link set "$IF_LAN" up
sudo ip link set "$IF_LAN" multicast on

echo
echo "Interfaces atuais:"
ip addr show dev "$IF_LAN"