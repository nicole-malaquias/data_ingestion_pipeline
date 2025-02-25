import sys
sys.path.append('/opt/airflow')

import logging
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
from utils.etl import run_etl

default_args = {
    'owner': 'nicole',
    'start_date': datetime(2024, 2, 1),
    'retries': 1
}

def run_bigquery_etl():
    logging.info("Iniciando o processo de ETL para BigQuery")
    try:
        run_etl()
        logging.info("Processo de ETL concluído com sucesso")
    except Exception as e:
        logging.error(f"Erro durante o processo de ETL: {e}")
        raise

with DAG('backfill', schedule_interval=None, default_args=default_args, catchup=False) as dag:
    etl_task = PythonOperator(
        task_id='bigquery_etl',
        python_callable=run_bigquery_etl
    )