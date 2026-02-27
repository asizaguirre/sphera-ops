#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   Simulação de Interoperabilidade - K-Sphera Ops         ${NC}"
echo -e "${CYAN}==========================================================${NC}\n"

# 1. Nginx
echo -e "${GREEN}[1] TESTE: Nginx Load Balancer${NC}"
echo -e "Objetivo: Verificar se o Gateway distribui requisições entre as instâncias de API (Round-Robin)."
echo "-----------------------------------------------------------------------"
echo "Requisição 1:"
curl -s http://localhost | grep "Hostname" || echo -e "${RED}Falha na conexão${NC}"
echo "Requisição 2:"
curl -s http://localhost | grep "Hostname" || echo -e "${RED}Falha na conexão${NC}"
echo ""

# 2. Redis
echo -e "${GREEN}[2] TESTE: Redis Cache Replication${NC}"
echo -e "Objetivo: Validar escrita no Master e replicação de leitura no Slave."
echo "-----------------------------------------------------------------------"
TEST_KEY="simulacao_$(date +%s)"
echo "Escrevendo chave '$TEST_KEY' no Redis Master..."
docker exec redis-master redis-cli set $TEST_KEY "OK_Replicado" > /dev/null
echo "Lendo chave '$TEST_KEY' do Redis Slave..."
VAL=$(docker exec redis-slave redis-cli get $TEST_KEY)
if [ "$VAL" == "OK_Replicado" ]; then
    echo -e "Resultado: ${GREEN}Sucesso (Valor: $VAL)${NC}"
else
    echo -e "Resultado: ${RED}Falha (Valor: $VAL)${NC}"
fi
echo ""

# 3. Kafka
echo -e "${GREEN}[3] TESTE: Kafka Messaging Cluster${NC}"
echo -e "Objetivo: Verificar saúde do cluster e capacidade de criação de tópicos."
echo "-----------------------------------------------------------------------"
TOPIC_NAME="topic-simulacao-$(date +%s)"
echo "Criando tópico '$TOPIC_NAME'..."
docker exec kafka-01 kafka-topics --create --topic $TOPIC_NAME --bootstrap-server kafka-01:29092 --partitions 1 --replication-factor 1 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "Tópico criado. Listando tópicos existentes:"
    docker exec kafka-01 kafka-topics --list --bootstrap-server kafka-01:29092 | grep $TOPIC_NAME
else
    echo -e "${RED}Erro ao criar tópico no Kafka.${NC}"
fi
echo ""

# 4. PostgreSQL
echo -e "${GREEN}[4] TESTE: PostgreSQL Database${NC}"
echo -e "Objetivo: Validar persistência de dados no banco primário."
echo "-----------------------------------------------------------------------"
echo "Criando tabela de teste e inserindo registro..."
docker exec -e PGPASSWORD=admin db-primary psql -U postgres -d ksphera_db -c "CREATE TABLE IF NOT EXISTS simulacao (id serial PRIMARY KEY, data text);" > /dev/null 2>&1
docker exec -e PGPASSWORD=admin db-primary psql -U postgres -d ksphera_db -c "INSERT INTO simulacao (data) VALUES ('Persistencia_Funcional');" > /dev/null 2>&1
echo "Consultando registro inserido:"
docker exec -e PGPASSWORD=admin db-primary psql -U postgres -d ksphera_db -c "SELECT * FROM simulacao ORDER BY id DESC LIMIT 1;"
echo ""

echo -e "${CYAN}Simulação concluída.${NC}"