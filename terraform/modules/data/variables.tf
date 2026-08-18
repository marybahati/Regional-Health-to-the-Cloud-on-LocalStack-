variable "secret_name" {
  type        = string
  description = "Secrets Manager secret name for the DB envelope."
  default     = "regional-health/db"
}

variable "db_name" {
  type        = string
  description = "MySQL database name."
  default     = "capacity_lab"
}

variable "db_host" {
  type        = string
  description = "Aiven MySQL host."
  sensitive   = true
}

variable "db_port" {
  type        = number
  description = "Aiven MySQL port."
  default     = 3306
}

variable "db_username" {
  type        = string
  description = "Aiven MySQL username."
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "Aiven MySQL password."
  sensitive   = true
}
