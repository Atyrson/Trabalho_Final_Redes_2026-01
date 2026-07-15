#!/bin/bash
#
# Menu para executar scripts de configuração dos roteadores
# Topologia: s - r1 - r2 - x - y
#

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Diretório onde estão os scripts (ajuste conforme sua estrutura)
SCRIPT_DIR="./scripts"  # ou "../scripts" dependendo de onde está

# Função para listar scripts disponíveis
listar_scripts() {
    echo -e "${BLUE}Scripts disponíveis:${NC}"
    echo "----------------------------------------"
    
    local i=1
    declare -a scripts
    
    # Procura por todos os scripts .sh na pasta (sem verificar se é executável)
    while IFS= read -r script; do
        if [ -f "$script" ]; then
            scripts[$i]="$script"
            nome=$(basename "$script")
            # Verifica se é executável para mostrar indicador
            if [ -x "$script" ]; then
                echo -e "${GREEN}$i)${NC} $nome ${BLUE}[executável]${NC}"
            else
                echo -e "${YELLOW}$i)${NC} $nome ${RED}[não executável]${NC}"
            fi
            ((i++))
        fi
    done < <(find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" 2>/dev/null | sort)
    
    # Se não encontrou na pasta scripts, procura na atual
    if [ ${#scripts[@]} -eq 0 ]; then
        echo -e "${YELLOW}Nenhum script encontrado em $SCRIPT_DIR${NC}"
        echo -e "${YELLOW}Procurando na pasta atual...${NC}"
        
        while IFS= read -r script; do
            if [ -f "$script" ]; then
                scripts[$i]="$script"
                nome=$(basename "$script")
                if [ -x "$script" ]; then
                    echo -e "${GREEN}$i)${NC} $nome ${BLUE}[executável]${NC}"
                else
                    echo -e "${YELLOW}$i)${NC} $nome ${RED}[não executável]${NC}"
                fi
                ((i++))
            fi
        done < <(find . -maxdepth 1 -name "*.sh" ! -name "menu.sh" 2>/dev/null | sort)
    fi
    
    echo "----------------------------------------"
    echo -e "${RED}0) Sair${NC}"
    echo
    
    # Retorna o array de scripts
    echo "${#scripts[@]}" > /tmp/script_count
    for idx in "${!scripts[@]}"; do
        echo "$idx:${scripts[$idx]}" >> /tmp/scripts_list
    done
}

# Função para executar script escolhido
executar_script() {
    local escolha=$1
    
    if [ "$escolha" -eq 0 ]; then
        echo -e "${GREEN}Saindo...${NC}"
        exit 0
    fi
    
    # Lê o script da lista
    script_path=$(grep "^$escolha:" /tmp/scripts_list | cut -d':' -f2-)
    
    if [ -n "$script_path" ] && [ -f "$script_path" ]; then
        echo -e "${GREEN}Executando: $(basename "$script_path")${NC}"
        echo "----------------------------------------"
        echo
        
        # Verifica se o script é executável
        if [ -x "$script_path" ]; then
            # Executa o script diretamente se for executável
            "$script_path"
        else
            # Executa com bash se não for executável
            echo -e "${YELLOW}Script não é executável. Executando com bash...${NC}"
            bash "$script_path"
        fi
        
        echo
        echo "----------------------------------------"
        echo -e "${GREEN}Script finalizado!${NC}"
    else
        echo -e "${RED}Opção inválida!${NC}"
    fi
}

# Menu principal
main() {
    while true; do
        clear
        echo "========================================="
        echo "  GERENCIADOR DE SCRIPTS - ROTEADORES"
        echo "  Topologia: [s] --- [r1] --- [r2] --- [x] --- [y]"
        echo "========================================="
        echo
        
        # Limpa arquivos temporários
        > /tmp/scripts_list
        > /tmp/script_count
        
        listar_scripts
        
        read -p "Escolha uma opção: " opcao
        
        if [[ "$opcao" =~ ^[0-9]+$ ]]; then
            executar_script "$opcao"
        else
            echo -e "${RED}Por favor, digite um número!${NC}"
        fi
        
        echo
        read -p "Pressione ENTER para continuar..."
    done
}

# Executa o menu
main