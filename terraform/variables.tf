variable "aws_region" { type = string  default = "eu-west-1" }

variable "app_name"   { type = string }  # e.g. "wavebudget-next"
variable "env"        { type = string default = "dev" }

# Networking
variable "vpc_cidr" { type = string default = "10.20.0.0/16" }

# ECS / App
variable "container_port" { type = number default = 3000 }
variable "desired_count"  { type = number default = 1 }
variable "cpu"            { type = number default = 512 }
variable "memory"         { type = number default = 1024 }

# IMPORTANT: image is passed in tfvars after GHCR build
variable "image_uri" {
  type        = string
  description = "Container image URI (e.g., ghcr.io/org/repo:sha)"
}

# DB config
variable "db_name" { type = string default = "appdb" }
variable "db_user" { type = string default = "appuser" }
variable "db_port" { type = number default = 5432 }

variable "db_instance_class" { type = string default = "db.t4g.micro" }
variable "db_allocated_storage" { type = number default = 20 }

# Public access (ALB)
variable "alb_listener_port" { type = number default = 80 }

# Optional: lock down inbound CIDRs to ALB (defaults open)
variable "alb_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "alb_logs_bucket_name" {
  type        = string
  default     = null
  description = "Pre-existing S3 bucket name for ALB access logs."
}

variable "waf_log_destination_arn" {
  type        = string
  default     = null
  description = "Pre-existing WAF log destination ARN (e.g., Kinesis Firehose delivery stream ARN)."
}
