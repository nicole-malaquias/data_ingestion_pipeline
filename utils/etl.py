import logging
import os
import glob
import shutil
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.functions import col, current_timestamp
from pyspark.sql.types import IntegerType, StringType, TimestampType
from google.cloud import bigquery
from concurrent.futures import ThreadPoolExecutor
from .data_validation import validate_data

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def create_spark_session(app_name="ETL_PySpark") -> SparkSession:
    """Cria uma sessão Spark com o conector do BigQuery."""
    logging.info(f"Iniciando a criação da sessão Spark: {app_name}")
    try:
        spark = SparkSession.builder \
            .appName(app_name) \
            .config("spark.jars.packages", "com.google.cloud.spark:spark-bigquery-with-dependencies_2.12:0.30.0") \
            .getOrCreate()
        logging.info("Sessão Spark criada com sucesso.")
        return spark
    except Exception as e:
        logging.error(f"Erro ao criar sessão Spark: {e}")
        raise

def extract_bigquery_data(spark: SparkSession) -> DataFrame:
    """Extrai dados da tabela pública do BigQuery."""
    logging.info("Extraindo dados do BigQuery.")
    try:
        df = spark.read \
            .format("bigquery") \
            .option("table", "basedosdados:br_inep_saeb.aluno_ef_9ano") \
            .load()
        logging.info("Dados extraídos com sucesso.")
        return df
    except Exception as e:
        logging.error(f"Erro na extração: {e}")
        raise

def transform_data(df: DataFrame) -> DataFrame:
    """Transforma os dados extraídos."""
    logging.info("Transformando dados.")
    try:
        df_transformed = df.select(
        col("ano").cast(IntegerType()),
        col("id_regiao").cast(StringType()),
        col("escola_publica").cast(IntegerType()),
        col("desempenho_aluno").cast(StringType()),
        col("sigla_uf").cast(StringType())
    ).na.drop(subset=["ano", "sigla_uf", "desempenho_aluno","id_regiao","escola_publica"]) \
    .withColumn("update_at", current_timestamp().cast(TimestampType()))

        logging.info(f"Transformação concluída. Registros: {df_transformed.count()}")
        return df_transformed
    except Exception as e:
        logging.error(f"Erro na transformação: {e}")
        raise

def insert_data_via_load_job(dataframe: DataFrame, table_id: str):
    """Insere dados no BigQuery usando um Load Job."""
    logging.info(f"Iniciando carga para o BigQuery: {table_id}")
    try:
        client = bigquery.Client()

        temp_dir = "/tmp/temp_data_csv"
        os.makedirs(temp_dir, exist_ok=True)

        
        dataframe.coalesce(1).write.option("header", True).mode("overwrite").csv(temp_dir)
        logging.info(f"CSV salvo em: {temp_dir}")

        csv_files = glob.glob(f"{temp_dir}/*.csv")
        if not csv_files:
            raise FileNotFoundError("Nenhum arquivo CSV encontrado.")
        csv_file = csv_files[0]

        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
            schema=[
                bigquery.SchemaField("ano", "INTEGER", mode="REQUIRED"),
                bigquery.SchemaField("id_regiao", "STRING"),
                bigquery.SchemaField("escola_publica", "INTEGER"),
                bigquery.SchemaField("desempenho_aluno", "STRING"),
                bigquery.SchemaField("sigla_uf", "STRING"),
                bigquery.SchemaField("update_at", "TIMESTAMP") 
            ]
        )

        with open(csv_file, "rb") as source_file:
            load_job = client.load_table_from_file(source_file, table_id, job_config=job_config)

        load_job.result()
        logging.info(f"Dados carregados com sucesso na tabela: {table_id}")

        # Removendo arquivos temporários após enviar pro BQ
        shutil.rmtree(temp_dir)
        logging.info("Diretório temporário removido.")

    except Exception as e:
        logging.error(f"Erro ao carregar dados no BigQuery: {e}")
        raise

def get_max_year(df: DataFrame) -> int:
    """Obtém o maior ano disponível na fonte de dados."""
    max_year = df.selectExpr("max(ano) as max_year").collect()[0]["max_year"]
    logging.info(f"Maior ano na fonte: {max_year}")
    return max_year if max_year else 0

def get_max_year_in_destination(table_id: str) -> int:
    """Obtém o maior ano disponível na tabela de destino."""
    logging.info(f"Obtendo o maior ano na tabela de destino: {table_id}")
    try:
        client = bigquery.Client()
        query = f"SELECT MAX(ano) as max_year FROM `{table_id}`"
        result = client.query(query).result()
        max_year = next(result).max_year
        logging.info(f"Maior ano na tabela de destino: {max_year if max_year else 'Nenhum dado'}")
        return max_year if max_year else 0
    except Exception as e:
        logging.error(f"Erro ao obter o maior ano da tabela de destino: {e}")
        raise

def run_etl():
    """Executa o processo completo de ETL."""
    logging.info("Iniciando processo ETL.")
    try:
        spark = create_spark_session()
        df = extract_bigquery_data(spark)
        transformed_df = transform_data(df)
        validate_data(transformed_df)
        insert_data_via_load_job(transformed_df, 'letrus-data.baseletrus.aluno_ef_9ano_transformado')
        spark.stop()
        logging.info("ETL concluído com sucesso.")
    except Exception as e:
        logging.error(f"Falha no ETL: {e}")
        raise

def run_incremental_etl():
    """Executa o ETL incremental baseado no campo 'ano' com processamento paralelo."""
    destination_table = "letrus-data.baseletrus.aluno_ef_9ano_transformado"
    spark = create_spark_session("Incremental_ETL")
    try:
        
        df_source = extract_bigquery_data(spark)
        
        # Obtém o maior ano disponível na origem e na tabela de destino
        max_year_source = get_max_year(df_source)
        max_year_dest = get_max_year_in_destination(destination_table)
        
        if max_year_source > max_year_dest:
            # Define os anos que ainda não foram processados
            missing_years = list(range(max_year_dest + 1, max_year_source + 1))
            logging.info(f"Anos pendentes para processamento: {missing_years}")
            
            def process_year(year):
                logging.info(f"Iniciando processamento para o ano {year}")
                df_year = df_source.filter(col("ano") == year)
                if df_year.count() == 0:
                    logging.info(f"Nenhum dado encontrado para o ano {year}.")
                    return

                transformed = transform_data(df_year)

                validate_data(transformed)

                insert_data_via_load_job(transformed, destination_table)
                logging.info(f"Processamento do ano {year} concluído.")

            with ThreadPoolExecutor() as executor:
                executor.map(process_year, missing_years)
        else:
            logging.info("Nenhum dado novo para carregar. A tabela já está atualizada.")
    except Exception as e:
        logging.error(f"Erro no ETL incremental: {e}")
        raise
    finally:
        spark.stop()