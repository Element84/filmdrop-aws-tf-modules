output "certificate_fqdn" {
  description = "The fqdn of the certificate validation record."
  value       = aws_route53_record.cert_validation.fqdn
}
