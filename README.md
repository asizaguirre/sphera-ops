# K-Sphera Ops - Desafio Técnico

Este repositório contém a arquitetura e automação para uma solução on-premises utilizando Nginx, Redis, Kafka e PostgreSQL.

## Como utilizar este repositório

### 0. Pré-requisitos (Ambiente Local)
Para rodar a validação localmente, suba a infraestrutura com Docker Compose:
```bash
docker-compose up -d
```

### 1. Documentação
O desenho da solução e as justificativas técnicas estão no arquivo [ARCHITECTURE.md](./ARCHITECTURE.md).

### 2. Automação (Ansible)
Para executar as operações de manutenção do banco de dados (Backup e Status Check):

```bash
# Navegue até a pasta ansible
cd ansible

# Execute o playbook (modo simulação/check primeiro)
ansible-playbook -i inventory.ini postgres_dia2.yml --check

# Execute o playbook para valer
ansible-playbook -i inventory.ini postgres_dia2.yml
```

### 3. Validação
O script em `scripts/validate_stack.sh` pode ser utilizado para testar a conectividade básica entre os componentes configurados.

### 4. Simulação de Tráfego
Para validar a interoperabilidade completa (Nginx, Redis, Kafka, Postgres) com logs detalhados de objetivo e ação:

```bash
chmod +x scripts/simulate_traffic.sh
./scripts/simulate_traffic.sh
```

## Testes de Interoperabilidade

Após subir o ambiente com `docker-compose up -d`, você pode validar o funcionamento de cada componente:

### 1. Nginx (Load Balancer)
O Nginx está balanceando carga entre `api-01` e `api-02`.
```bash
# Execute várias vezes e observe o "Hostname" mudar entre api-01 e api-02
curl http://localhost
```

### 2. Redis (Cache)
Teste a replicação entre Master e Slave.
```bash
# Escrever no Master
docker exec redis-master redis-cli set chave "teste-redis"
# Ler do Slave
docker exec redis-slave redis-cli get chave
```

### 3. Kafka (Mensageria)
Crie um tópico e envie uma mensagem.
```bash
# Criar tópico
docker exec kafka-01 kafka-topics --create --topic teste-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
# Listar tópicos
docker exec kafka-01 kafka-topics --list --bootstrap-server localhost:9092
```