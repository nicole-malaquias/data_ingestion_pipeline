# Infraestrutura como Código (IaC)

Esta documentação detalha a estrutura de IaC implementada para provisionar recursos no Google Cloud Platform (GCP) via Terraform. O objetivo é automatizar a criação de datasets e tabelas no BigQuery para suportar nossa pipeline de dados.

## Estrutura de Arquivos

```
infra/
├── main.tf           # Configuração principal do BigQuery
├── outputs.tf        # Definição dos outputs
├── provider.tf       # Configuração do GCP
├── terraform.tfvars  # Valores das variáveis
└── variables.tf      # Declaração de variáveis
```

## Detalhamento dos Componentes

### main.tf

#### Dataset Configuration
```hcl
dataset_id = [via variável]
location = [região configurada]
friendly_name = "Meu Dataset"
description = "Dataset criado via Terraform"
default_table_expiration_ms = 3600000  # 1 hora
```

#### Table Configuration
- **Particionamento**: Por ano (1995-2100)
- **Clusterização**: ano, id_regiao
- **Schema**:

| Campo            | Tipo      | Requisito |
|-----------------|-----------|-----------|
| ano             | INTEGER   | NULLABLE  |
| sigla_uf        | STRING    | NULLABLE  |
| id_regiao       | STRING    | NULLABLE  |
| escola_publica  | INTEGER   | NULLABLE  |
| desempenho_aluno| STRING    | NULLABLE  |
| update_at       | TIMESTAMP | NULLABLE  |

### outputs.tf
- `dataset_id`: Identificador do dataset
- `table_id`: Identificador da tabela

### provider.tf
- Provedor: Google Cloud
- Configurações:
  - Projeto
  - Região
  - Autenticação (token.json)

### terraform.tfvars
```hcl
project_id = "letrus-data"
dataset_id = "baseletrus"
table_id   = "aluno_ef_9ano_transformado"
```

### variables.tf
| Variável    | Descrição                    | Default        |
|-------------|------------------------------|----------------|
| project_id  | ID do projeto GCP           | -              |
| region      | Região dos recursos         | us-central1    |
| dataset_id  | ID do dataset BigQuery      | -              |
| table_id    | ID da tabela BigQuery       | -              |