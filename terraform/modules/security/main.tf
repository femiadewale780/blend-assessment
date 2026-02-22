# ALB SG: allow inbound from internet on 80 (or whatever listener uses)
resource "aws_security_group" "alb" {
  name        = "sg-alb-${var.name}"
  description = "ALB SG"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "sg-alb-${var.name}" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_in" {
  for_each          = toset(var.alb_ingress_cidrs)
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_out" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ECS SG: allow inbound only from ALB SG to container_port
resource "aws_security_group" "ecs" {
  name        = "sg-ecs-${var.name}"
  description = "ECS tasks SG"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "sg-ecs-${var.name}" })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_out" {
  security_group_id = aws_security_group.ecs.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# RDS SG: allow inbound from ECS SG to db_port
resource "aws_security_group" "rds" {
  name        = "sg-rds-${var.name}"
  description = "RDS SG"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "sg-rds-${var.name}" })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_in_https" {
  for_each          = toset(var.alb_ingress_cidrs)
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}


resource "aws_vpc_security_group_egress_rule" "rds_out" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
