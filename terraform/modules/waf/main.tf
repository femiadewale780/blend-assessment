resource "aws_wafv2_web_acl" "this" {
  name  = "waf-${var.name}"
  scope = var.scope

  # Exactly one default_action block, with nested allow/block chosen dynamically
  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
    metric_name                = "waf-${var.name}"
    sampled_requests_enabled   = var.sampled_requests_enabled
  }

  # Optional: rate limit rule (commonly used in front of ALBs)
  dynamic "rule" {
    for_each = var.enable_rate_limit ? [1] : []
    content {
      name     = "RateLimit"
      priority = var.rate_limit_priority

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.rate_limit
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
        metric_name                = "ratelimit-${var.name}"
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  # AWS Managed Rules - Common Rule Set
  dynamic "rule" {
    for_each = var.enable_common_rule_set ? [1] : []
    content {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = var.common_rule_priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
        metric_name                = "common-${var.name}"
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  # AWS Managed Rules - Known Bad Inputs
  dynamic "rule" {
    for_each = var.enable_known_bad_inputs_rule_set ? [1] : []
    content {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = var.known_bad_inputs_priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
        metric_name                = "badinputs-${var.name}"
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  tags = var.tags
}
