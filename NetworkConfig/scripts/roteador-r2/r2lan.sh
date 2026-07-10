#!/bin/bash
#
# Configuração das interfaces de rede internas do R2 (Rede dos Clientes e opcionalmente Link com R1)
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

echo "=== [R2] Configuração das Interfaces Internas e Rotas ==="
echo

# 1. Seleção da Interface para a rede dos Clientes (X e Y)
IF_CLIENTES=$(escolher_item "Selecione a interface conectada à rede dos Clientes (X e Y):" "$(list_net_interfaces)")
read -rp "Endereço IP para a rede de Clientes [padrão 192.168.0.1/24]: " IP_CLIENTES
IP_CLIENTES=${IP_CLIENTES:-192.168.0.1/24}
echo

# Pergunta se deseja configurar o link com o R1 agora
read -rp "Deseja configurar a interface conectada ao Roteador R1 agora? [S/n] " conf_r1
conf_r1=${conf_r1:-S}

CONFIGURAR_R1=false
IF_R1=""
IP_R1=""

if [[ "$conf_r1" =~ ^[sS]$ ]]; then
    CONFIGURAR_R1=true
    # Filtra a interface que já foi escolhida para os Clientes para não duplicar
    INTERFACES_RESTANTES=$(list_net_interfaces | grep -v -w "$IF_CLIENTES")
    IF_R1=$(escolher_item "Selecione a interface conectada ao Roteador R1 (Rede Core):" "$INTERFACES_RESTANTES")
    read -rp "Endereço IP para a rede Core [padrão 10.0.0.2/24]: " IP_R1
    IP_R1=${IP_R1:-10.0.0.2/24}
    echo
fi

echo "Resumo da Configuração:"
echo "  Interface p/ Clientes X e Y : $IF_CLIENTES ($IP_CLIENTES)"
if [ "$CONFIGURAR_R1" = true ]; then
    echo "  Interface p/ Roteador R1 ...: $IF_R1 ($IP_R1)"
    echo "  Gateway Padrão (Internet/S) : 10.0.0.1"
else
    echo "  Interface p/ Roteador R1 ...: [PULADO PELO USUÁRIO]"
fi
echo
read -rp "Confirma as configurações? [s/N] " confirma
if [[ ! "$confirma" =~ ^[sS]$ ]]; then
    echo "Abortado pelo usuário."
    exit 1
fi

echo -e "\n[R2] Desativando NetworkManager para evitar conflitos..."
sudo systemctl stop NetworkManager || true

# Configurando a perna dos Clientes
echo "[R2] Configurando interface dos Clientes ($IF_CLIENTES)..."
sudo ip addr flush dev "$IF_CLIENTES"
sudo ip addr add "$IP_CLIENTES" dev "$IF_CLIENTES"
sudo ip link set "$IF_CLIENTES" up
sudo ip link set "$IF_CLIENTES" multicast on

# Configurando a perna do Roteador R1 (Se aplicável)
if [ "$CONFIGURAR_R1" = true ]; then
    echo "[R2] Configurando interface do Roteador R1 ($IF_R1)..."
    sudo ip addr flush dev "$IF_R1"
    sudo ip addr add "$IP_R1" dev "$IF_R1"
    sudo ip link set "$IF_R1" up
    sudo ip link set "$IF_R1" multicast on

    # Adicionando o Default Gateway apontando para o R1
    echo "[R2] Configurando R1 (10.0.0.1) como o Gateway Padrão..."
    sudo ip route del default 2>/dev/null || true
    sudo ip route add default via 10.0.0.1
fi

# Ativando o Roteamento no Kernel (IP Forwarding)
echo "[R2] Ativando encaminhamento de pacotes IP (IP Forwarding)..."
sudo sysctl -w net.ipv4.ip_forward=1

echo -e "\n=== Configuração concluída com sucesso! ==="
echo "Estado das interfaces modificadas:"
ip -br addr show dev "$IF_CLIENTES"
if [ "$CONFIGURAR_R1" = true ]; then
    ip -br addr show dev "$IF_R1"
fi
echo -e "\nTabela de Roteamento Atual:"
ip route show