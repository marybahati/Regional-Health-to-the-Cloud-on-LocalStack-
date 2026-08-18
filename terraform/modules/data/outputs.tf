output "db_endpoint" {
  value       = var.db_host
  description = "Aiven MySQL host (also stored in the secret envelope)."
}

output "db_port" {
  value       = tonumber(var.db_port)
  description = "Aiven MySQL port."
}

output "db_name" {
  value       = var.db_name
  description = "Database name."
}

output "db_username" {
  value       = var.db_username
  description = "Database username (not the password)."
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.db.arn
  description = "ARN passed to user-data. Never the secret value."
}

output "secret_name" {
  value       = aws_secretsmanager_secret.db.name
  description = "Secrets Manager name."
}

output "patient_count" {
  value       = var.patient_count
  description = "Seed row count the bootstrap script must load."
}
