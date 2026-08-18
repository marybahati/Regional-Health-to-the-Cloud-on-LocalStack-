output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB envelope."
  value       = aws_secretsmanager_secret.db.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret."
  value       = aws_secretsmanager_secret.db.name
}

output "db_endpoint" {
  description = "MySQL host (Aiven)."
  value       = var.db_host
}

output "db_port" {
  description = "MySQL port."
  value       = var.db_port
}
