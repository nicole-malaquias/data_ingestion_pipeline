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
COPY --chown=airflow:airflow requirements.txt ${AIRFLOW_HOME}/requirements.txt

# Instala as dependências listadas no requirements.txt
RUN pip install --no-cache-dir -r ${AIRFLOW_HOME}/requirements.txt




