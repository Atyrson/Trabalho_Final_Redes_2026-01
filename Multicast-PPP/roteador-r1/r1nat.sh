#!/bin/bash
#
# Configuração de Source NAT (masquerade) no R1 - Versão Segura/Fail-Safe
#
set -euo pipefail # -u: falha se usar variável não declarada; -o pipefail: falha se o grep/awk falhar no meio

# 1. Validação de Privilégio (Garante que não vai travar pedindo senha no meio)
if [ "$EUID" -ne 0 ]; then
    echo "[ERRO] Este script precisa ser executado como ROOT (use sudo)." >&2
    exit 1
fi

list_net_interfaces() {
    ip -o link show \
        | awk -F': ' '{print $2}' \
        | grep -Ev '^(lo|ppp[0-9]*|docker|veth|br-|virbr)' \
        | sort
}

# 2. Permite passar a interface por argumento para evitar interação na apresentação
IF_WAN="${1:-}"

if [ -z "$IF_WAN" ]; then
    echo "=== Modo Interativo: Nenhuma interface passada por argumento ===" >&2
    
    arr=()
    while IFS= read -r linha; do
        [ -n "$linha" ] && arr+=("$linha")
    done <<< "$(list_net_interfaces)"

    if [ ${#arr[@]} -eq 0 ]; then
        echo "[ERRO] Nenhuma interface de rede válida encontrada." >&2
        exit 1
    fi

    echo "Selecione a interface conectada à Internet:" >&2
    select escolha in "${arr[@]}"; do
        if [ -n "$escolha" ]; then
            IF_WAN="$escolha"
            break
        else
            echo "Opção inválida." >&2
        fi
    done
fi

echo "Using interface: $IF_WAN"

# 3. Execução Segura e Idempotente
echo "[R1] Subindo interface de uplink ($IF_WAN)..."
ip link set "$IF_WAN" up

echo "[R1] Ativando roteamento IP de forma persistente nesta sessão..."
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "[R1] Configurando Source NAT (masquerade) via $IF_WAN..."
# O uso do -C evita duplicar regras se o script rodar duas vezes
iptables -t nat -C POSTROUTING -o "$IF_WAN" -j MASQUERADE 2>/dev/null \
    || iptables -t nat -A POSTROUTING -o "$IF_WAN" -j MASQUERADE

echo
echo "=== Configuração Concluída com Sucesso! ==="
iptables -t nat -L POSTROUTING -v -n