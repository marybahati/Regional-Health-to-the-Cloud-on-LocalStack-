# =============================================================================
# modules/data — Aiven MySQL credentials → Secrets Manager   (GROUP-OWNED)
#
# RDS is not on LocalStack Hobby. The real DB is Aiven (free). Terraform only
# publishes the connection envelope. Password comes from TF_VAR_db_password
# (env / CI secrets), never from git.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

resource "aws_secretsmanager_secret" "db" {
  name                    = var.secret_name
  recovery_window_in_days = 0
  tags = {
    Service = var.service_name
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    engine   = "mysql"
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = tonumber(var.db_port)
    dbname   = var.db_name
    ca       = var.db_ca_cert
  })
}
