output "db_host" {
  value = aws_db_instance.this.address
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
