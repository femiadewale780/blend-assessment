variable "name" {
  type        = string
  description = "Base name used for WAF resources (e.g. app-env)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to WAF resources."
}

variable "scope" {
  type        = string
  default     = "REGIONAL"
  description = "WAF scope. Use REGIONAL for ALB, APIGW; CLOUDFRONT for CloudFront."
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "default_action" {
  type        = string
  default     = "allow"
  description = "Default action for requests not matching rules: allow or block."
  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "default_action must be allow or block."
  }
}

# --- Managed rule groups toggles & priorities ---
variable "enable_common_rule_set" {
  type    = bool
  default = true
}

variable "common_rule_priority" {
  type    = number
  default = 10
}

variable "enable_known_bad_inputs_rule_set" {
  type    = bool
  default = true
}

variable "known_bad_inputs_priority" {
  type    = number
  default = 20
}

# --- Optional: Rate limiting ---
variable "enable_rate_limit" {
  type    = bool
  default = false
}

variable "rate_limit" {
  type        = number
  default     = 2000
  description = "Requests per 5-minute period per IP when rate limit is enabled."
}

variable "rate_limit_priority" {
  type    = number
  default = 5
}

# --- Metrics / visibility ---
variable "cloudwatch_metrics_enabled" {
  type    = bool
  default = true
}

variable "sampled_requests_enabled" {
  type    = bool
  default = true
}

variable "enable_waf_logging" {
  type    = bool
  default = true
}

variable "waf_log_destination_arn" {
  type        = string
  default     = null
  description = "Existing WAF log destination ARN (commonly a Kinesis Firehose delivery stream ARN). Required if enable_waf_logging=true."
}
