#!/bin/bash
#
# Configuração da interface de rede e gateway padrão do Cliente X
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

echo "=== [X] Configuração da Interface de Rede e Gateway Padrão ==="
echo

# 1. Seleção da Interface conectada ao R2
IF_X=$(escolher_item "Selecione a interface conectada ao Roteador R2:" "$(list_net_interfaces)")

# 2. Definição do IP do Cliente X
read -rp "Endereço IP do Cliente X [padrão 192.168.0.2/24]: " IP_X
IP_X=${IP_X:-192.168.0.2/24}

# 3. Definição do Gateway Padrão (IP do R2)
read -rp "Endereço IP do Gateway Padrão (R2) [padrão 192.168.0.1]: " GW_X
GW_X=${GW_X:-192.168.0.1}

echo
echo "Resumo da Configuração:"
echo "  Interface .......: $IF_X"
echo "  Endereço IP .....: $IP_X"
echo "  Gateway Padrão ..: $GW_X"
echo
read -rp "Confirma as configurações? [s/N] " confirma
if [[ ! "$confirma" =~ ^[sS]$ ]]; then
    echo "Abortado pelo usuário."
    exit 1
fi

echo -e "\n[X] Desativando NetworkManager para evitar conflitos..."
sudo systemctl stop NetworkManager || true

echo "[X] Limpando endereços antigos de $IF_X..."
sudo ip addr flush dev "$IF_X"

echo "[X] Configurando endereço IP..."
sudo ip addr add "$IP_X" dev "$IF_X"
sudo ip link set "$IF_X" up
sudo ip link set "$IF_X" multicast on

echo "[X] Configurando o Gateway Padrão (Rota para R2)..."
# Remove a rota default antiga caso exista para não causar conflito
sudo ip route del default 2>/dev/null || true
sudo ip route add default via "$GW_X"

echo -e "\n=== Configuração concluída com sucesso! ==="
echo "Estado atual da interface:"
ip -br addr show dev "$IF_X"
echo -e "\nTabela de Roteamento Atual:"
ip route show