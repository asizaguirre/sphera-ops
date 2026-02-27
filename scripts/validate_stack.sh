#!/bin/bash

# ==============================================================================
# Script de Validação de Conectividade - K-Sphera Ops
# Descrição: Testa a conectividade TCP com os componentes da infraestrutura
# definidos no inventory.ini.
# ==============================================================================

# Definição de Cores para Output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verifica se o netcat (nc) está instalado
if ! command -v nc &> /dev/null; then
    echo -e "${RED}Erro: O utilitário 'nc' (netcat) não foi encontrado.${NC}"
    echo "Por favor, instale-o para continuar (ex: sudo apt install netcat)."
    exit 1
fi

echo -e "${YELLOW}Iniciando validação de conectividade da Stack K-Sphera...${NC}"
echo "----------------------------------------------------------------"
printf "%-25s %-20s %-10s %-10s\n" "SERVIÇO" "HOST" "PORTA" "STATUS"
echo "----------------------------------------------------------------"

# Função para testar conexão
check_service() {
    local service_name=$1
    local host=$2
    local port=$3

    # nc -z: Zero-I/O mode (apenas scan)
    # -w 2: Timeout de 2 segundos
    if nc -z -w 2 "$host" "$port" 2>/dev/null; then
        printf "%-25s %-20s %-10s ${GREEN}ONLINE${NC}\n" "$service_name" "$host" "$port"
    else
        printf "%-25s %-20s %-10s ${RED}OFFLINE${NC}\n" "$service_name" "$host" "$port"
    fi
}

# --- Definição dos Alvos (Baseado no inventory.ini) ---

# 1. Gateway / Load Balancer
check_service "Nginx Gateway"       "127.0.0.1" "80"

# 2. Banco de Dados (PostgreSQL)
check_service "Postgres Primary"    "127.0.0.1" "5432"
check_service "Postgres Standby"    "127.0.0.1" "5433"

# 3. Cache (Redis)
check_service "Redis Master"        "127.0.0.1" "6379"
check_service "Redis Replica"       "127.0.0.1" "6380"

# 4. Mensageria (Kafka Cluster)
check_service "Kafka Broker 01"     "127.0.0.1" "9092"
check_service "Kafka Broker 02"     "127.0.0.1" "9093"
check_service "Kafka Broker 03"     "127.0.0.1" "9094"

echo "----------------------------------------------------------------"
echo -e "${YELLOW}Validação concluída.${NC}"

# Executar simulação de tráfego se o script existir
SIMULATE_SCRIPT="./scripts/simulate_traffic.sh"
if [ -f "$SIMULATE_SCRIPT" ]; then
    echo ""
    echo -e "${YELLOW}Iniciando testes de simulação de tráfego...${NC}"
    chmod +x "$SIMULATE_SCRIPT"
    "$SIMULATE_SCRIPT"
fi

# Executar simulação de comunicação se o script existir
COMM_SCRIPT="./scripts/simulate_communication.sh"
if [ -f "$COMM_SCRIPT" ]; then
    echo ""
    chmod +x "$COMM_SCRIPT"
    "$COMM_SCRIPT"
fi
