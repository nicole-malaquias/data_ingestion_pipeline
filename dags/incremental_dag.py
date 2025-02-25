import sys
sys.path.append('/opt/airflow')

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
from utils.etl import run_incremental_etl

default_args = {
    'owner': 'nicole',
    'depends_on_past': False,
    'start_date': datetime(2024, 2, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'incremental_fill',
    default_args=default_args,
    description='Ingestão incremental semanal com base no campo ano',
    schedule_interval='@weekly',
    catchup=False
) as dag:

    incremental_etl_task = PythonOperator(
        task_id='run_incremental_etl',
        python_callable=run_incremental_etl,
        provide_context=True
    )

    incremental_etl_task
