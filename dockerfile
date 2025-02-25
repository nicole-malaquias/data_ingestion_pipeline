# FROM apache/airflow:2.10.5

# USER root

# # Instala Java (OpenJDK 17) e dependências do sistema
# RUN apt-get update && \
#     apt-get install -y openjdk-17-jdk && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

# # Define o JAVA_HOME e atualiza o PATH
# ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
# ENV PATH=$JAVA_HOME/bin:$PATH

# # Troca para o usuário airflow para instalar pacotes Python
# USER airflow

# # Instala PySpark, bibliotecas do Google Cloud e Great Expectations
# RUN pip install --no-cache-dir \
#     pyspark==3.5.0 \
#     google-cloud-bigquery \
#     google-cloud-storage \
#     google-auth \
#     google-auth-oauthlib \
#     google-api-python-client \
#     great_expectations \
#     boto3 \
#     python-dotenv


FROM apache/airflow:2.10.5

USER root

# Instala Java (OpenJDK 17) e dependências do sistema
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Define o JAVA_HOME e atualiza o PATH
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Troca para o usuário airflow para instalar pacotes Python
USER airflow

# Copia o arquivo de requisitos para o container
# Certifique-se de que o arquivo "requirements.txt" esteja no mesmo diretório que o Dockerfile
COPY --chown=airflow:airflow requirements.txt ${AIRFLOW_HOME}/requirements.txt

# Instala as dependências listadas no requirements.txt
RUN pip install --no-cache-dir -r ${AIRFLOW_HOME}/requirements.txt




