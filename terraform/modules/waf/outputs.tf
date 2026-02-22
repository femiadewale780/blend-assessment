output "web_acl_arn" {
  value       = aws_wafv2_web_acl.this.arn
  description = "ARN of the WAFv2 Web ACL. Use this in aws_wafv2_web_acl_association."
}

output "web_acl_id" {
  value       = aws_wafv2_web_acl.this.id
  description = "ID of the WAFv2 Web ACL."
}

output "web_acl_name" {
  value       = aws_wafv2_web_acl.this.name
  description = "Name of the WAFv2 Web ACL."
}
