#!/bin/bash
#
# Configuração do R2 via Arquivo de Peer (wan_r2)
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

echo "=== [R2] Configuração do Enlace PPP ==="
echo

# 1. Seleção do dispositivo serial
SERIAL_PPP=$(escolher_item "Selecione o dispositivo serial do enlace PPP:" "$(list_serial_devices)")
echo

# 2. Definição dos IPs do enlace WAN
read -rp "IP local do R2 no enlace PPP [padrão 10.0.0.2]: " IP_LOCAL
IP_LOCAL=${IP_LOCAL:-10.0.0.2}
read -rp "IP remoto de R1 no enlace PPP [padrão 10.0.0.1]: " IP_REMOTO
IP_REMOTO=${IP_REMOTO:-10.0.0.1}

echo
echo "Resumo da Configuração:"
echo "  Dispositivo serial ......: $SERIAL_PPP"
echo "  IP local (R2) ...........: $IP_LOCAL"
echo "  IP remoto (R1) ..........: $IP_REMOTO"
echo "  Velocidade ..............: 115200 bps"
echo
read -rp "Confirma a aplicação dessas configurações? [s/N] " confirma
if [[ ! "$confirma" =~ ^[sS]$ ]]; then
    echo "Abortado pelo usuário."
    exit 1
fi

echo
echo "[R2] Criando/Atualizando arquivo de configuração em /etc/ppp/peers/wan_r2..."
sudo mkdir -p /etc/ppp/peers
sudo tee /etc/ppp/peers/wan_r2 > /dev/null <<EOF
$SERIAL_PPP
115200
$IP_LOCAL:$IP_REMOTO
local
noauth
lock
persist
defaultroute
EOF

echo "[R2] Limpando processos antigos e chamando 'pppd call wan_r2'..."
sudo killall pppd 2>/dev/null || true
sleep 1
sudo pppd call wan_r2

echo "[R2] Aguardando a interface ppp0 subir..."
for i in {1..10}; do
    if ip link show ppp0 &>/dev/null; then
        break
    fi
    sleep 1
done

if ip link show ppp0 &>/dev/null; then
    sudo ip link set ppp0 multicast on
    echo "[R2] Configurando R1 como Gateway Padrão e rotas de multicast..."
    sudo ip route del default 2>/dev/null || true
    sudo ip route add default via "$IP_REMOTO" dev ppp0
    sudo ip route add 224.0.0.0/4 dev ppp0 || true
    echo
    echo "=== [SUCESSO] R2 configurado via arquivo de peer! ==="
    ip addr show dev ppp0
else
    echo "[ERRO] A interface ppp0 não subiu. Verifique os cabos físicos."
    exit 1
fi
