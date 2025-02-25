# Pipeline de Dados

## Descrição

Este projeto tem como objetivo realizar a ingestão, transformação, validação e carga de dados da base pública do governo brasileiro (SAEB - 9º Ano) utilizando ferramentas modernas de orquestração e processamento de dados. O pipeline é composto por dois fluxos principais: Backfill (processamento completo de dados) e Incremental (processamento apenas de dados novos).

### Fonte dos Dados 

Base: basedosdados.br_inep_saeb.aluno_ef_9ano
Frequência de Atualização dos Dados: Bienal (a cada 2 anos)

## Arquitetura do Projeto
O projeto é orquestrado com Apache Airflow e utiliza o Docker para garantir portabilidade e fácil deploy. O processamento de dados é realizado com PySpark e a validação é feita com Great Expectations.

### Principais Componentes
Airflow: Orquestração das pipelines.
Docker & Docker Compose: Containerização dos serviços.
PySpark: Processamento distribuído de dados.
Great Expectations: Validação da qualidade dos dados.
Google BigQuery: Armazenamento dos dados tratados.

### 🗃️ Estrutura de Pastas

```
.
├── README.md                   # Documentação do projeto
├── docker-compose.yaml         # Configuração dos containers
├── dockerfile                  # Definição da imagem Docker
├── requirements.txt            # Dependências do projeto
├── dags/                       # DAGs do Airflow
│   ├── backfill_dag.py         # Pipeline de carga completa (Backfill)
│   └── incremental_dag.py      # Pipeline de ingestão incremental
├── utils/                      # Funções auxiliares
│   ├── etl.py                  # Lógica de extração, transformação e carga
│   └── data_validation.py      # Validações de qualidade com Great Expectations
├── great_expectations/         # Configurações e checkpoints de validação
│   ├── checkpoints             # Checkpoints para validação de dados
│   ├── expectations            # Regras e expectativas de dados
│   ├── great_expectations.yml  # Arquivo de configuração do GE
│   └── profilers               # Perfis de dados gerados
├── infra/                      # Infraestrutura como código (Terraform)
│   ├── main.tf                 # Criação dos recursos (BigQuery, etc.)
│   ├── outputs.tf              # Saídas dos recursos criados
│   ├── provider.tf             # Provedor do Terraform (GCP)
│   ├── terraform.tfvars        # Variáveis definidas pelo usuário
│   ├── variables.tf            # Definição de variáveis
│   ├── terraform.tfstate       # Estado atual da infraestrutura
│   └── terraform.tfstate.backup# Backup do estado da infraestrutura

```

### Como Executar o Projeto

Para executar este projeto, é necessário ter os seguintes pré-requisitos instalados em seu computador:

* [Python](https://www.python.org/downloads/) (recomendado: versão 3.8 ou superior)

* [Docker](https://www.docker.com/get-started/) (necessário para orquestração com Airflow e execução dos containers)

* [Terraform](https://developer.hashicorp.com/terraform/tutorials) (alternativa para não ter que criar a infraestrutura de armazenamento manualmente)

* [Great Expactation](https://maikpaixao.medium.com/data-quality-with-great-expectation-in-python-0908b179f615)(ferramenta que auxilia na qualidade de validação dos dados)

### Passo a Passo 

Com todo as ferramentas instaladas em seu ambiente, agora é só seguir o passo a passo a seguir 

```
git clone git@github.com:nicole-malaquias/data_ingestion_pipeline.git
cd data_ingestion_pipeline
```

### Levantando sua Infra 

Para que seja possivel fazer inserção de dados  é preciso provisionar um recurso de armazenamento na cloud, por motivos de custo, esse projeto usa o google bigquery e asseguir terá os passos auxiliando a configura-lo para seu projeto. 

#### Integração com o BigQuery

Este projeto utiliza o **[BigQuery](https://support.google.com/cloud/answer/9113366?hl=pt-BR#:~:text=O%20BigQuery%20%C3%A9%20um%20servi%C3%A7o,administrador%20de%20banco%20de%20dados.)** como solução de armazenamento de dados. Para integrar o projeto ao data warehouse, é necessário ativar uma **conta de serviço** no console da **Google Cloud Platform (GCP)**.

### 🔑 Recursos úteis

- 🛠️ **Ativar interações externas no GCP:**  
  Siga o guia detalhado para habilitar seu console da GCP e permitir interações externas:  
  👉 [Como ativar o serviço de transferência no BigQuery](https://cloud.google.com/bigquery/docs/enable-transfer-service?hl=pt-br)

- 🗝️ **Criar uma conta de serviço e gerar credenciais:**  
  Aprenda a criar uma conta de serviço e gerar a credencial necessária para autenticação com o Google:  
  👉 [Guia para criar uma conta de serviço no GCP](https://support.site24x7.com/portal/en/kb/articles/how-to-create-a-service-account-in-gcp-console)

- 🛠️ **Criando Projeto dentro do Console GCP:** 
  Apos os passos acima por fim crie um projeto com o nome "letrus". 
  👉 [Como de como criar o projeto](https://medium.com/@camila-marquess/criando-um-projeto-no-dbt-utilizando-o-bigquery-c49fc8375aa2#:~:text=Cria%C3%A7%C3%A3o%20do%20Projeto%20no%20GCP&text=D%C3%AA%20um%20nome%20ao%20seu,clique%20em%20continue%20e%20Done.)


Como esse projeto será executado apenas para fins demostrativos de como fazer o fluxo de extração , transformação e carregamento, adicione o token extraido na raiz do projeto. 

#### Terraform apply 

No seu terminal vá até a pasta infra, certifique-se que esteja dentro dela, então execute o terraform para que crie o mesma estrutura de armazenamento em seu console gcp. 

```
terraform applay
``` 

#### Configure e inicie o Docker:

Certifique-se de que o Docker está rodando em sua máquina.
Para instalar o Docker, siga o guia oficial: Instalação do Docker
Inicie os containers com o comando:

```
docker-compose up -d
```

#### Executando o Airflow 

Assim que todo os containers estiverem *up* acesse [localhost:8000](http://localhost:8080/)

Use as credenciais padrão (se aplicável):
- Usuário: airflow
- Senha: airflow

#### Execute os DAGs:

No Airflow, ative e execute os DAGs desejados:

**backfill**: Esta DAG tem como objetivo realizar a carga inicial de dados, preenchendo o banco de dados com todas as informações atualmente disponíveis na base pública. Deve ser executada apenas uma vez para popular o histórico de dados.


**incremental_fill**: Esta DAG realiza a ingestão incremental, verificando se há dados mais recentes na base pública do governo. Caso sejam identificados novos registros, a DAG realiza a ingestão apenas desses dados, garantindo que o banco de dados permaneça atualizado sem redundâncias.







