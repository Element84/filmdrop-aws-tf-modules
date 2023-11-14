output "web_acl_id" {
  description = "The id of the WAF resource created."
  value       = aws_waf_web_acl.waf_acl.id
}

