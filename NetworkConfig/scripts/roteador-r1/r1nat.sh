#!/bin/bash
#
# Configuração de Source NAT (masquerade) no R1 - Versão Segura/Fail-Safe
#
set -euo pipefail 

# 1. Validação de Privilégio 
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

# 2. Permite passar a interface por argumento para evitar interação
IF_WAN="${1:-}"

if [ -z "$IF_WAN" ]; then
    echo "=== Modo Interativo: Nenhuma interface passada por argumento ===" >&2
    
    # Criando o array de forma compatível com 'set -u'
    unset arr
    arr=()
    while IFS= read -r linha; do
        if [ -n "$linha" ]; then
            arr+=("$linha")
        fi
    done <<< "$(list_net_interfaces)"

    if [ ${#arr[@]} -eq 0 ]; then
        echo "[ERRO] Nenhuma interface de rede válida encontrada." >&2
        exit 1
    fi

    echo "Selecione a interface conectada à Internet (WAN):" >&2
    
    # Define temporariamente um valor para a resposta do select para evitar problemas com set -u
    REPLY="" 
    select escolha in "${arr[@]}"; do
        if [ -n "${escolha:-}" ]; then
            IF_WAN="$escolha"
            break
        else
            echo "Opção inválida." >&2
        fi
    done
fi

echo "Interface selecionada para internet: $IF_WAN"
echo

# 3. Execução Segura e Idempotente
echo "[R1] Garantindo que a interface de uplink ($IF_WAN) está ativa..."
ip link set "$IF_WAN" up

echo "[R1] Ativando roteamento IP no Kernel (IP Forwarding)..."
sysctl -w net.ipv4.ip_forward=1

echo "[R1] Configurando Source NAT (Masquerade) via $IF_WAN..."
# O uso do -C evita duplicar regras se o script rodar duas vezes
if ! iptables -t nat -C POSTROUTING -o "$IF_WAN" -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o "$IF_WAN" -j MASQUERADE
    echo "[R1] Regra de MASQUERADE adicionada com sucesso."
else
    echo "[R1] Regra de MASQUERADE já existia. Nada alterado."
fi

echo
echo "=== Configuração do NAT Concluída com Sucesso! ==="
echo "Regras de POSTROUTING ativas:"
iptables -t nat -L POSTROUTING -v -n
echo "Mostrando outras regras"
iptables -t nat -S