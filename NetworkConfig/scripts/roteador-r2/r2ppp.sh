#!/bin/bash
#
# Configuração do enlace PPP (R2 <-> R1) via cabo serial RS-232, a 115200 bps
#
set -e

list_serial_devices() {
    ls /dev/ttyS* /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || true
}

escolher_item() {
    local titulo="$1"
    local itens="$2"
    local arr=()
    while IFS= read -r linha; do
        [ -n "$linha" ] && arr+=("$linha")
    done <<< "$itens"

    if [ ${#arr[@]} -eq 0 ]; then
        echo "[ERRO] Nenhum dispositivo serial encontrado." >&2
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

echo "=== [R2] Configuração do enlace PPP (R2 <-> R1) ==="
echo

SERIAL_PPP=$(escolher_item "Selecione o dispositivo serial do enlace PPP:" "$(list_serial_devices)")

# Inversão dos padrões: O local agora é o R2 (10.0.0.2) e o remoto é o R1 (10.0.0.1)
read -rp "IP local do R2 no enlace PPP [padrão 10.0.0.2]: " IP_LOCAL
IP_LOCAL=${IP_LOCAL:-10.0.0.2}
read -rp "IP remoto de R1 no enlace PPP [padrão 10.0.0.1]: " IP_REMOTO
IP_REMOTO=${IP_REMOTO:-10.0.0.1}

echo
echo "Resumo:"
echo "  Dispositivo serial ...: $SERIAL_PPP"
echo "  IP local (R2) ........: $IP_LOCAL"
echo "  IP remoto (R1) .......: $IP_REMOTO"
echo "  Velocidade ...........: 115200 bps"
read -rp "Confirma? [s/N] " confirma
if [[ ! "$confirma" =~ ^[sS]$ ]]; then
    echo "Abortado pelo usuário."
    exit 1
fi

echo "[R2] Subindo enlace PPP em $SERIAL_PPP (115200 bps)"
# O pppd recebe "IP_LOCAL:IP_REMOTO", garantindo a atribuição correta em cada ponta
sudo pppd "$SERIAL_PPP" 115200 "$IP_LOCAL:$IP_REMOTO" noauth local persist &

echo "[R2] Aguardando ppp0 subir..."
for i in {1..10}; do
    if ip link show ppp0 &>/dev/null; then
        break
    fi
    sleep 1
done

if ip link show ppp0 &>/dev/null; then
    sudo ip link set ppp0 multicast on
    echo "[R2] Configurando R1 como Gateway Padrão via ppp0"
    
    # Remove qualquer rota padrão antiga para evitar conflitos e adiciona a nova via PPP
    sudo ip route del default 2>/dev/null || true
    sudo ip route add default via "$IP_REMOTO" dev ppp0
    
    # Mantém suporte a tráfego multicast se necessário no laboratório
    sudo ip route add 224.0.0.0/4 dev ppp0 || true
    echo
    echo "ppp0 configurado com sucesso no R2:"
    ip addr show dev ppp0
else
    echo "[AVISO] ppp0 não subiu a tempo. Verifique o cabo/config do pppd em ambas as pontas."
    exit 1
fi