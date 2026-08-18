variable "service_name" {
  type        = string
  description = "Owning service (service-a / service-b / service-c)."
}

variable "db_host" {
  type        = string
  description = "Aiven MySQL hostname. Set TF_VAR_db_host. Never commit."
}

variable "db_port" {
  type        = string
  description = "Aiven MySQL port (string so it maps cleanly from env)."
}

variable "db_username" {
  type        = string
  description = "Aiven username, usually avnadmin."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Aiven password. Set TF_VAR_db_password. Never commit."
}

variable "db_name" {
  type        = string
  description = "MySQL database name (often defaultdb on Aiven free)."
  default     = "defaultdb"
}

variable "db_ca_cert" {
  type        = string
  sensitive   = true
  description = "Aiven CA PEM. Set TF_VAR_db_ca_cert. Never commit."
}

variable "secret_name" {
  type        = string
  description = "Secrets Manager name for the DB envelope."
  default     = "regional-health/service-a/db"
}

variable "patient_count" {
  type        = number
  description = "Documented seed size. Do not hardcode in SQL; scripts read this."
  default     = 10000
}
