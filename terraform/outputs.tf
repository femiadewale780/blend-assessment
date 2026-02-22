output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "db_secret_arn" {
  value = module.secrets.db_secret_arn
}
