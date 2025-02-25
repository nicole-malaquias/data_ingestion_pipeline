resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.dataset_id
  location                    = var.region
  friendly_name               = "Meu Dataset"
  description                 = "Dataset criado via Terraform"
  default_table_expiration_ms = 3600000

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [dataset_id]
  }
}


resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_id

  schema = jsonencode([
    {
      name = "ano"
      type = "INTEGER"
      mode = "REQUIRED"
    },
    {
      name = "id_regiao"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "sigla_uf"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "escola_publica"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "desempenho_aluno"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "update_at"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    }
  ])
}
