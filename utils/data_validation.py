import sys
import logging

sys.path.append('/opt/airflow')
from great_expectations.dataset.sparkdf_dataset import SparkDFDataset

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def validate_data(df):
    logging.info("Iniciando validação dos dados.")
    ge_df = SparkDFDataset(df)
    
   
    logging.info("Validando que a coluna 'ano' não contenha valores nulos.")
    resultado_not_null = ge_df.expect_column_values_to_not_be_null("ano")
    if not resultado_not_null.success:
        logging.error("Falha na validação: a coluna 'ano' contém valores nulos.")
    
    logging.info("Validando que a coluna 'ano' esteja nos tipos esperados (IntegerType ou LongType).")
    resultado_tipo = ge_df.expect_column_values_to_be_in_type_list("ano", ["IntegerType", "LongType"])
    if not resultado_tipo.success:
        logging.error("Falha na validação: a coluna 'ano' não está em IntegerType ou LongType.")
    
    
    logging.info("Validando que os valores da coluna 'ano' estejam entre 1900 e 2100.")
    resultado_intervalo = ge_df.expect_column_values_to_be_between("ano", min_value=1900, max_value=2100)
    if not resultado_intervalo.success:
        logging.error("Falha na validação: a coluna 'ano' contém valores fora do intervalo 1900-2100.")
    
    if not (resultado_not_null.success and resultado_tipo.success and resultado_intervalo.success):
        logging.error("Validação dos dados falhou. Verifique os logs para mais detalhes.")
        raise Exception("Validação dos dados falhou. Verifique os logs para mais detalhes.")
    
    logging.info("Validação dos dados concluída com sucesso.")
    return df
