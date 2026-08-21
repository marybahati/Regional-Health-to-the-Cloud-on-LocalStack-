variable "app_ami_id" {
  type        = string
  description = "AMI id ami-<12 hex chars> matching the tagged localstack-ec2 image."
}

variable "enable_compute" {
  type        = bool
  description = "EC2 + ELBv2. Requires LocalStack Pro (LOCALSTACK_AUTH_TOKEN). Set false for community."
  default     = true
}

variable "patient_count" {
  type        = number
  description = "Seed size. Scripts read this; do not hardcode in SQL."
  default     = 10000
}

variable "db_host" {
  type        = string
  description = "Aiven host. Export TF_VAR_db_host."
}

variable "db_port" {
  type        = string
  description = "Aiven port. Export TF_VAR_db_port."
}

variable "db_username" {
  type        = string
  description = "Aiven user. Export TF_VAR_db_username."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Aiven password. Export TF_VAR_db_password."
}

variable "db_name" {
  type        = string
  default     = "defaultdb"
  description = "Aiven database name. Export TF_VAR_db_name."
}

variable "db_ca_cert" {
  type        = string
  sensitive   = true
  description = "Aiven CA PEM. Export TF_VAR_db_ca_cert."
}
