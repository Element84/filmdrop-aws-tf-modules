output "certificate_arn" {
  description = "The arn of the AWS ACM certificate."
  value       = aws_acm_certificate.cert.arn
}
