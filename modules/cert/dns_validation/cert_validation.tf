resource "aws_route53_record" "cert_validation" {
  name    = var.name
  type    = var.type
  zone_id = var.zone_id
  records = var.records
  ttl     = 60
}
