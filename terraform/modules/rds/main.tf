resource "random_password" "db" {
  length  = 24
  special = true
}

resource "aws_db_subnet_group" "this" {
  name       = "rds-subnet-${var.name}"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "rds-subnet-${var.name}" })
}

resource "aws_db_instance" "this" {
  identifier = "rds-${var.name}"

  engine         = "postgres"
  engine_version = "16" # you can override later if needed

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.db_user
  password = random_password.db.result
  port     = var.db_port

  vpc_security_group_ids = [var.rds_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  publicly_accessible = false
  skip_final_snapshot = true

  storage_encrypted = true
  deletion_protection = false

  tags = merge(var.tags, { Name = "rds-${var.name}" })
}
