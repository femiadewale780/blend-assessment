variable "name" { type = string }
variable "tags" { 
    type = map(string) 
    default = {} 
}

variable "vpc_id"            { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id"         { type = string }

variable "listener_port" { type = number }
variable "target_port"   { type = number }

variable "enable_https" {
  type    = bool
  default = true
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for the ALB HTTPS listener"
  default     = null
}

variable "ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_http_redirect" {
  type    = bool
  default = true
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "waf_web_acl_arn" {
  type        = string
  description = "Existing WAFv2 Web ACL ARN to associate with the ALB (optional). If null, module can create one if you choose."
  default     = null
}

variable "enable_access_logs" {
  type    = bool
  default = true
}

variable "access_logs_bucket" {
  type        = string
  default     = null
  description = "Existing S3 bucket name for ALB access logs. Required if enable_access_logs=true."
}

variable "access_logs_prefix" {
  type    = string
  default = null
}

