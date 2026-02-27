#!/bin/bash
set -e

# Definição de Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================================${NC}"
echo -e "${BLUE}   Simulação de Tráfego e Teste de Interoperabilidade K-Sphera Ops   ${NC}"
echo -e "${BLUE}=====================================================================${NC}"

# 1. Nginx Load Balancing
echo -e "\n${GREEN}[1] Componente: Nginx API Gateway${NC}"
echo "Objetivo: Validar o roteamento e o balanceamento de carga Round-Robin entre as APIs."
echo "Ação: Enviando 4 requisições HTTP sequenciais para http://localhost..."
echo "----------------------------------------------------------------"

if command -v curl &> /dev/null; then
    for i in {1..4}; do
        # Extrai apenas o Hostname da resposta do container whoami
        RESPONSE=$(curl -s http://localhost | grep "Hostname" | awk '{print $2}')
        if [ -z "$RESPONSE" ]; then
            echo "   Req $i: Falha ao conectar"
        else
            echo "   Req $i: Atendido por container -> $RESPONSE"
        fi
        sleep 0.5
    done
else
    echo "   Erro: 'curl' não está instalado."
fi

# 1.1 Teste de Carga (Apache Bench)
echo -e "\n${GREEN}[1.1] Componente: Nginx (Teste de Carga)${NC}"
echo "Objetivo: Executar um teste de carga leve para verificar a estabilidade do Gateway."
echo "Ação: Enviando 100 requisições com concorrência de 10..."
echo "----------------------------------------------------------------"

if command -v ab &> /dev/null; then
    # -n 100: Total de requisições
    # -c 10: Concorrência
    # -q: Quiet (suprime output detalhado)
    ab -n 100 -c 10 -q http://localhost/ > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   Resultado: SUCESSO - Teste de carga concluído sem erros."
    else
        echo "   Resultado: FALHA - Ocorreram erros durante o teste de carga."
    fi
else
    echo "   Aviso: 'ab' (Apache Bench) não encontrado. Pule este teste ou instale com 'sudo apt install apache2-utils'."
fi

# 2. Redis Replication
echo -e "\n${GREEN}[2] Componente: Redis Cache Cluster${NC}"
echo "Objetivo: Validar a persistência no Master e a replicação de leitura no Slave."
echo "Ação: Escrevendo dados no Master e lendo do Slave..."
echo "----------------------------------------------------------------"

TEST_KEY="simulacao_$(date +%s)"
echo "   1. Escrevendo chave '$TEST_KEY' no Redis Master..."
docker exec redis-master redis-cli set "$TEST_KEY" "Dados_Sincronizados_OK" > /dev/null

echo "   2. Aguardando replicação (1s)..."
sleep 1

echo "   3. Lendo chave '$TEST_KEY' do Redis Slave..."
VALUE=$(docker exec redis-slave redis-cli get "$TEST_KEY" | tr -d '\r')

if [ "$VALUE" == "Dados_Sincronizados_OK" ]; then
    echo "   Resultado: SUCESSO - Valor '$VALUE' recuperado do Slave."
else
    echo "   Resultado: FALHA - Valor esperado não encontrado no Slave."
fi

# 3. Kafka Messaging
echo -e "\n${GREEN}[3] Componente: Kafka Event Streaming${NC}"
echo "Objetivo: Validar o fluxo completo de mensagens (Produção -> Tópico -> Consumo)."
echo "Ação: Criando tópico, produzindo e consumindo mensagem de teste..."
echo "----------------------------------------------------------------"

TOPIC_NAME="test-topic-$(date +%s)"
MESSAGE="Evento de Teste K-Sphera $(date)"

echo "   1. Criando tópico '$TOPIC_NAME'..."
docker exec kafka-01 kafka-topics --create --topic "$TOPIC_NAME" --bootstrap-server kafka-01:29092 --partitions 1 --replication-factor 1 > /dev/null 2>&1 || echo "      (Tópico já existe ou aviso ignorado)"

sleep 2

echo "   2. Produzindo mensagem: '$MESSAGE'..."
echo "$MESSAGE" | docker exec -i kafka-01 kafka-console-producer --bootstrap-server kafka-01:29092 --topic "$TOPIC_NAME" > /dev/null 2>&1

echo "   3. Consumindo mensagem..."
CONSUMED=$(docker exec kafka-01 kafka-console-consumer --bootstrap-server kafka-01:29092 --topic "$TOPIC_NAME" --from-beginning --max-messages 1 --timeout-ms 5000 2>/dev/null)

if [[ "$CONSUMED" == *"$MESSAGE"* ]]; then
    echo "   Resultado: SUCESSO - Mensagem recebida: '$CONSUMED'"
else
    echo "   Resultado: FALHA - Mensagem não recebida ou timeout."
fi

# 4. PostgreSQL Database
echo -e "\n${GREEN}[4] Componente: PostgreSQL Database${NC}"
echo "Objetivo: Validar a conectividade e a capacidade de execução de queries SQL."
echo "Ação: Executando query de teste 'SELECT 1' no banco Primário..."
echo "----------------------------------------------------------------"

DB_CHECK=$(docker exec db-primary psql -U postgres -d ksphera_db -c "SELECT 1 as status;" 2>&1)

if [[ "$DB_CHECK" == *"1"* ]]; then
    echo "   Resultado: SUCESSO - Query executada corretamente."
else
    echo "   Resultado: FALHA - Não foi possível conectar ao banco."
    echo "   Erro: $DB_CHECK"
fi

echo -e "\n${BLUE}=== Simulação Concluída ===${NC}"