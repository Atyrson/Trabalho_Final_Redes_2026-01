#!/bin/bash
#
# Configuração do R1 via Arquivo de Peer (wan_r1)
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

echo "=== [R1] Configuração do Enlace PPP ==="
echo

# 1. Seleção do dispositivo serial
SERIAL_PPP=$(escolher_item "Selecione o dispositivo serial do enlace PPP:" "$(list_serial_devices)")
echo

# 2. Definição dos IPs do enlace WAN
read -rp "IP local do R1 no enlace PPP [padrão 10.0.0.1]: " IP_LOCAL
IP_LOCAL=${IP_LOCAL:-10.0.0.1}
read -rp "IP remoto de R2 no enlace PPP [padrão 10.0.0.2]: " IP_REMOTO
IP_REMOTO=${IP_REMOTO:-10.0.0.2}

echo
echo "Resumo da Configuração:"
echo "  Dispositivo serial ......: $SERIAL_PPP"
echo "  IP local (R1) ...........: $IP_LOCAL"
echo "  IP remoto (R2) ..........: $IP_REMOTO"
echo "  Velocidade ..............: 115200 bps"
echo
read -rp "Confirma a aplicação dessas configurações? [s/N] " confirma
if [[ ! "$confirma" =~ ^[sS]$ ]]; then
    echo "Abortado pelo usuário."
    exit 1
fi

echo
echo "[R1] Criando/Atualizando arquivo de configuração em /etc/ppp/peers/wan_r1..."
sudo mkdir -p /etc/ppp/peers
sudo tee /etc/ppp/peers/wan_r1 > /dev/null <<EOF
$SERIAL_PPP
115200
$IP_LOCAL:$IP_REMOTO
local
noauth
lock
persist
EOF

echo "[R1] Limpando processos antigos e chamando 'pppd call wan_r1'..."
sudo killall pppd 2>/dev/null || true
sleep 1
sudo pppd call wan_r1

echo "[R1] Aguardando a interface ppp0 subir..."
for i in {1..10}; do
    if ip link show ppp0 &>/dev/null; then
        break
    fi
    sleep 1
done