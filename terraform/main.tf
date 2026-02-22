locals {
  name = "${var.app_name}-${var.env}"

  # short prefix naming helper
  pfx = {
    vpc = "vpc"
    sg  = "sg"
    alb = "alb"
    ecs = "ecs"
    td  = "td"
    rds = "rds"
    sm  = "sm"
  }

  tags = {
    App = var.app_name
    Env = var.env
  }
}

module "vpc" {
  source   = "./modules/vpc"
  name     = local.name
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

module "security" {
  source            = "./modules/security"
  name              = local.name
  tags              = local.tags
  vpc_id            = module.vpc.vpc_id
  alb_ingress_cidrs = var.alb_ingress_cidrs
  container_port    = var.container_port
  db_port           = var.db_port
}

module "rds" {
  source               = "./modules/rds"
  name                 = local.name
  tags                 = local.tags
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  rds_sg_id            = module.security.rds_sg_id
  db_name              = var.db_name
  db_user              = var.db_user
  db_port              = var.db_port
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
}

# Store DB connection values (host/name/password/port) in Secrets Manager
module "secrets" {
  source     = "./modules/secrets"
  name       = local.name
  tags       = local.tags
  db_host    = module.rds.db_host
  db_name    = var.db_name
  db_password = module.rds.db_password
  db_port    = var.db_port
}

module "waf" {
  source = "./modules/waf"
  name   = local.name
  tags   = local.tags

  enable_rate_limit = true
  rate_limit        = 1500
  enable_waf_logging       = true
  waf_log_destination_arn  = var.waf_log_destination_arn
}

module "alb" {
  source           = "./modules/alb"
  name             = local.name
  tags             = local.tags
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id        = module.security.alb_sg_id
  listener_port    = var.alb_listener_port
  target_port      = var.container_port
  enable_access_logs  = true
  access_logs_bucket  = var.alb_logs_bucket_name   # existing bucket
  access_logs_prefix  = "apps/${var.app_name}/${var.env}"
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = module.alb.alb_arn
  web_acl_arn  = module.waf.web_acl_arn
}

module "ecs" {
  source             = "./modules/ecs"
  name               = local.name
  tags               = local.tags

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  ecs_sg_id          = module.security.ecs_sg_id
  container_port     = var.container_port

  image_uri          = var.image_uri
  desired_count      = var.desired_count
  cpu                = var.cpu
  memory             = var.memory

  # App needs DB_USER as env, while others come from Secrets Manager
  db_user            = var.db_user

  # Secret is JSON with keys DB_HOST/DB_NAME/DB_PASSWORD/DB_PORT
  db_secret_arn      = module.secrets.db_secret_arn

  # ALB integration
  target_group_arn   = module.alb.target_group_arn
}

