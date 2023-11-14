resource "aws_route53_record" "endpoint" {
  zone_id = var.zone_id
  name    = "${var.alias_hostname}.${var.alias_netname}"
  type    = "A"

  alias {
    name                   = var.alias_endpoint
    zone_id                = var.alias_endpoint_zone
    evaluate_target_health = true
  }
}
