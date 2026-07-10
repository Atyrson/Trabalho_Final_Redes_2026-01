#!/bin/bash
#
# Configuração das interfaces de rede internas do R1 (LAN #1 e opcionalmente Link com R2)
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

echo "=== [R1] Configuração das Interfaces Internas e Rotas ==="
echo

# 1. Seleção da Interface para o Servidor S
IF_S=$(escolher_item "Selecione a interface conectada à LAN #1 (Host S):" "$(list_net_interfaces)")
read -rp "Endereço IP para a LAN #1 [padrão 172.16.0.1/24]: " IP_S
IP_S=${IP_S:-172.16.0.1/24}
echo

# Ask if the user wants to configure R2 now
read -rp "Deseja configurar a interface conectada ao Roteador R2 agora? [S/n] " conf_r2
conf_r2=${conf_r2:-S}

CONFIGURAR_R2=false
IF_R2=""
IP_R2=""

if [[ "$conf_r2" =~ ^[sS]$ ]]; then
    CONFIGURAR_R2=true
    # Filtra a interface que já foi escolhida para o Host S para não listar duplicado
    INTERFACES_RESTANTES=$(list_net_interfaces | grep -v -w "$IF_S")
    IF_R2=$(escolher_item "Selecione a interface conectada ao Roteador R2 (Rede Core):" "$INTERFACES_RESTANTES")
    read -rp "Endereço IP para a rede Core [padrão 10.0.0.1/24]: " IP_R2
    IP_R2=${IP_R2:-10.0.0.1/24}
    echo
fi

echo "Resumo da Configuração:"
echo "  Interface p/ Servidor S ..: $IF_S ($IP_S)"
if [ "$CONFIGURAR_R2" = true ]; then
    echo "  Interface p/ Roteador R2 .: $IF_R2 ($IP_R2)"
    echo "  Rota Estática Adicional ..: 192.168.0.0/24 via 10.0.0.2"
else
    echo "  Interface p/ Roteador R2 .: [PULADO PELO USUÁRIO]"
fi
echo
read -rp "Confirma as configurações? [s/N] " confirma
if [[ ! "$confirma" =~ ^[sS]$ ]]; then
    echo "Abortado pelo usuário."
    exit 1
fi

echo -e "\n[R1] Desativando NetworkManager para evitar conflitos..."
sudo systemctl stop NetworkManager || true

# Configurando a perna do Servidor S
echo "[R1] Configurando interface do Servidor S ($IF_S)..."
sudo ip addr flush dev "$IF_S"
sudo ip addr add "$IP_S" dev "$IF_S"
sudo ip link set "$IF_S" up
sudo ip link set "$IF_S" multicast on

# Configurando a perna do Roteador R2 (Se aplicável)
if [ "$CONFIGURAR_R2" = true ]; then
    echo "[R1] Configurando interface do Roteador R2 ($IF_R2)..."
    sudo ip addr flush dev "$IF_R2"
    sudo ip addr add "$IP_R2" dev "$IF_R2"
    sudo ip link set "$IF_R2" up
    sudo ip link set "$IF_R2" multicast on

    # Adicionando a rota de retorno para os clientes X e Y através do R2
    echo "[R1] Adicionando rota estática para a rede dos clientes (192.168.0.0/24)..."
    sudo ip route del 192.168.0.0/24 via 10.0.0.2 2>/dev/null || true
    sudo ip route add 192.168.0.0/24 via 10.0.0.2
fi

# Ativando o Roteamento no Kernel (IP Forwarding)
echo "[R1] Ativando encaminhamento de pacotes IP (IP Forwarding)..."
sudo sysctl -w net.ipv4.ip_forward=1

echo -e "\n=== Configuração concluída com sucesso! ==="
echo "Estado das interfaces modificadas:"
ip -br addr show dev "$IF_S"
if [ "$CONFIGURAR_R2" = true ]; then
    ip -br addr show dev "$IF_R2"
fi
echo -e "\nTabela de Roteamento Atual:"
ip route show