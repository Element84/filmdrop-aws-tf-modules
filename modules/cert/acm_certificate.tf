resource "aws_acm_certificate" "cert" {
  domain_name       = var.alias_address
  validation_method = var.validation_method
}

module "certificate_dns_validation" {
  count = var.dns_validation == "true" ? 1 : 0

  source = "./dns_validation"

  name           = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  type           = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  zone_id        = var.zone_id
  records        = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  alias_address  = [var.alias_address]
}

resource "aws_acm_certificate_validation" "cert" {
  count = var.dns_validation == "true" ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [module.certificate_dns_validation[0].certificate_fqdn]
}
