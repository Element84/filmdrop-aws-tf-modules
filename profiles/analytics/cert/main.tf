

module "analytics_certificate" {
  count  = var.domain_alias == "" ? 0 : 1
  source = "../../../modules/cert"

  zone_id        = var.domain_zone
  alias_address  = var.domain_alias
  dns_validation = true
}
