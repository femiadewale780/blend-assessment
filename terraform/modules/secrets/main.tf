resource "aws_secretsmanager_secret" "db" {
  name = "sm-db-${var.name}"
  tags = merge(var.tags, { Name = "sm-db-${var.name}" })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    DB_HOST     = var.db_host
    DB_NAME     = var.db_name
    DB_PASSWORD = var.db_password
    DB_PORT     = tostring(var.db_port)
  })
}
