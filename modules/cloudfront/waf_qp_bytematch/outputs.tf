output "web_acl_id" {
  description = "The id of the WAF resource created."
  value       = aws_wafv2_web_acl.cf_web_acl.id
}

output "web_acl_arn" {
  description = "The ARN of the WAF resource created."
  value       = aws_wafv2_web_acl.cf_web_acl.arn
}
