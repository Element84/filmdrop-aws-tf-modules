output "certificate_arn" {
  description = "The arn of the AWS ACM certificate."
  value       = var.alias_address == "" ? "" : aws_acm_certificate.cert[0].arn
}
