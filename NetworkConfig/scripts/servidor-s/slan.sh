#!/bin/bash
#
# Configuração da interface de rede e gateway padrão do Servidor S
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

echo "=== [S] Configuração da Interface de Rede e Gateway Padrão ==="
echo

# 1. Seleção da Interface conectada ao R1
IF_S=$(escolher_item "Selecione a interface conectada ao Roteador R1:" "$(list_net_interfaces)")

# 2. Definição do IP do Servidor S
read -rp "Endereço IP do Servidor S [padrão 172.16.0.2/24]: " IP_S
IP_S=${IP_S:-172.16.0.2/24}

# 3. Definição do Gateway Padrão (IP do R1)
read -rp "Endereço IP do Gateway Padrão (R1) [padrão 172.16.0.1]: " GW_S
GW_S=${GW_S:-172.16.0.1}

echo
echo "Resumo da Configuração:"
echo "  Interface .......: $IF_S"
echo "  Endereço IP .....: $IP_S"
echo "  Gateway Padrão ..: $GW_S"
echo
read -rp "Confirma as configurações? [s/N] " confirma
if [[ ! "$confirma" =~ ^[sS]$ ]]; then
    echo "Abortado pelo usuário."
    exit 1
fi

echo -e "\n[S] Desativando NetworkManager para evitar conflitos..."
sudo systemctl stop NetworkManager || true

echo "[S] Limpando endereços antigos de $IF_S..."
sudo ip addr flush dev "$IF_S"

echo "[S] Configurando endereço IP..."
sudo ip addr add "$IP_S" dev "$IF_S"
sudo ip link set "$IF_S" up
sudo ip link set "$IF_S" multicast on

echo "[S] Configurando o Gateway Padrão (Rota para R1)..."
# Remove a rota default antiga caso exista para não causar conflito
sudo ip route del default 2>/dev/null || true
sudo ip route add default via "$GW_S"

echo -e "\n=== Configuração concluída com sucesso! ==="
echo "Estado atual da interface:"
ip -br addr show dev "$IF_S"
echo -e "\nTabela de Roteamento Atual:"
ip route show