# modules/data — Aiven MySQL credentials → Secrets Manager (GROUP-OWNED)
#
# Slack update: RDS is not on LocalStack Hobby. The managed database is Aiven
# MySQL. Terraform writes the connection envelope to Secrets Manager; the app
# resolves credentials at boot via GetSecretValue. No plaintext in git, image,
# or user-data.

resource "aws_secretsmanager_secret" "db" {
  name                    = var.secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    engine   = "mysql"
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = tostring(var.db_port)
    dbname   = var.db_name
  })
}
