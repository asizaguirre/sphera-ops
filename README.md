# K-Sphera Ops - Desafio Técnico

Este repositório contém a arquitetura e automação para uma solução on-premises utilizando Nginx, Redis, Kafka e PostgreSQL.

## 🚀 Como utilizar este repositório

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