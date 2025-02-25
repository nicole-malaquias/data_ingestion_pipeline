variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região do GCP"
  type        = string
  default     = "us-central1"
}

variable "dataset_id" {
  description = "ID do dataset do BigQuery"
  type        = string
}

variable "table_id" {
  description = "ID da tabela do BigQuery"
  type        = string
}
