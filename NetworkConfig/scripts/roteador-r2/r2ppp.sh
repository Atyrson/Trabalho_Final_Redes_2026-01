Aqui está o script do **R2** adaptado e padronizado com a mesma estrutura visual e de logs que deixamos no R1.

Ele mantém o foco exclusivo na inicialização do enlace PPP, na configuração do R1 como Gateway Padrão (permitindo que a LAN #2 acesse o servidor DNS e a Internet) e nas rotas de multicast necessárias para o funcionamento do IPTV:

```bash
#!/bin/bash
#
# Configuração do R2: Enlace PPP, Rota Padrão e Multicast
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

# 2. Definição dos IPs do enlace WAN (Invertido em relação ao R1)
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
echo "[R2] 1/2 - Subindo enlace PPP em $SERIAL_PPP (115200 bps)..."
sudo pppd "$SERIAL_PPP" 115200 "$IP_LOCAL:$IP_REMOTO" noauth local persist &

echo "[R2] 2/2 - Aguardando interface ppp0 subir..."
for i in {1..10}; do
    if ip link show ppp0 &>/dev/null; then
        break
    fi
    sleep 1
done

if ip link show ppp0 &>/dev/null; then
    sudo ip link set ppp0 multicast on
    echo "[R2] Configurando R1 como Gateway Padrão e rotas de multicast..."
    
    # Remove rota padrão antiga para evitar conflitos métricos e força a saída pelo PPP
    sudo ip route del default 2>/dev/null || true
    sudo ip route add default via "$IP_REMOTO" dev ppp0
    
    # Adiciona suporte a tráfego multicast na WAN de baixa performance
    sudo ip route add 224.0.0.0/4 dev ppp0 || true
    echo
    echo "=== [SUCESSO] Link PPP e rotas do R2 configurados! ==="
    ip addr show dev ppp0
else
    echo "[ERRO] A interface ppp0 não subiu a tempo. Verifique os cabos físicos e a conexão."
    exit 1
fi

```
