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
check_service "Nginx Gateway"       "192.168.10.10" "80"

# 2. Banco de Dados (PostgreSQL)
check_service "Postgres Primary"    "192.168.10.50" "5432"
check_service "Postgres Standby"    "192.168.10.51" "5432"

# 3. Cache (Redis)
check_service "Redis Master"        "192.168.10.40" "6379"
check_service "Redis Replica"       "192.168.10.41" "6379"

# 4. Mensageria (Kafka Cluster)
check_service "Kafka Broker 01"     "192.168.10.60" "9092"
check_service "Kafka Broker 02"     "192.168.10.61" "9092"
check_service "Kafka Broker 03"     "192.168.10.62" "9092"

echo "----------------------------------------------------------------"
echo -e "${YELLOW}Validação concluída.${NC}"
