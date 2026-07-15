 #!/bin/bash

# Garante que o script está sendo rodado como root
if [ "$EUID" -ne 0 ]; then
  echo "Erro: Por favor, execute este script como root (usando sudo)."
  exit 1
fi

echo "=========================================="
echo "1. Instalando e Atualizando o SMCRoute no R2..."
echo "=========================================="
if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y smcroute
elif command -v dnf &> /dev/null; then
    dnf install -y smcroute
else
    echo "Gerenciador de pacotes não automatizado. Certifique-se de que o 'smcroute' está instalado."
fi

echo ""
echo "=========================================="
echo "Interfaces de rede disponíveis no R2:"
echo "=========================================="
# Lista apenas as interfaces físicas/virtuais ativas no R2 (ignorando 'lo')
ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"
echo "=========================================="
echo ""

# Pergunta ao usuário quais interfaces configurar no R2
read -p "Interface de ENTRADA (vinda do R1): " INT_IN
read -p "Interface de SAÍDA (direcionada ao X): " INT_OUT
read -p "Endereço do grupo Multicast [Padrão: 239.1.1.1]: " MC_ADDR

# Se o usuário apenas apertar Enter, assume o padrão 239.1.1.1
MC_ADDR=${MC_ADDR:-239.1.1.1}

echo ""
echo "Aplicando configurações de rede no R2..."

# 1. Ativa o encaminhamento de pacotes IPv4 comuns e de Multicast no kernel do R2
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.mc_forwarding=1

# 2. Ativa a flag multicast nas interfaces selecionadas do R2
ip link set "$INT_IN" multicast on
ip link set "$INT_OUT" multicast on

# 3. Habilita e reinicia o serviço do SMCRoute
systemctl enable smcroute
systemctl restart smcroute

# Pequena pausa para garantir que o daemon subiu completamente
sleep 1

# 4. Adiciona a rota estática multicast no SMCRoute do R2
echo "Adicionando rota no R2: de $INT_IN para $INT_OUT via grupo $MC_ADDR..."
smcroutectl add "$INT_IN" "$MC_ADDR" "$INT_OUT"

echo ""
echo "✔ Configuração concluída com sucesso no R2!"
echo "Para verificar se as rotas de encaminhamento estão ativas, use: smcroutectl show"