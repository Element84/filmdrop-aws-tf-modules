resource "aws_acm_certificate" "cert" {
  count = var.alias_address == "" ? 0 : 1

  domain_name       = var.alias_address
  validation_method = var.validation_method
}

resource "aws_route53_record" "certificate_dns_validation" {
  count = var.alias_address != "" && var.dns_validation == true ? 1 : 0

  name    = var.alias_address == "" ? "" : tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_name
  type    = var.alias_address == "" ? "" : tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_type
  zone_id = var.zone_id
  records = var.alias_address == "" ? [] : [tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_value]
  ttl     = var.cert_ttl
}

resource "aws_acm_certificate_validation" "cert" {
  count = var.alias_address != "" && var.dns_validation == true ? 1 : 0

  certificate_arn         = var.alias_address == "" ? "" : aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [aws_route53_record.certificate_dns_validation[0].fqdn]
}

moved {
  from = aws_acm_certificate.cert
  to   = aws_acm_certificate.cert[0]
}
