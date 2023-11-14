module "cloudfront_certificate" {
  providers = {
    aws         = aws.east
  }

  source        = "../../cert/"

  zone_id       = var.zone_id
  alias_address = var.domain_alias
}

module "cloudfront_distribution" {
  providers = {
    aws         = aws.east
  }

  source = "../custom"

  ssl_certificate_arn                       = module.cloudfront_certificate.certificate_arn
  log_prefix                                = "${var.project_name}-${var.application_name}"
  domain_aliases                            = [var.domain_alias]
  cloudfront_origin_access_identity_arn     = var.cloudfront_origin_access_identity_arn
  cloudfront_access_identity_path           = var.cloudfront_access_identity_path
  logging_origin_id                         = var.logging_origin_id
  logging_domain_name                       = var.logging_domain_name
  error_pages_id                            = var.error_pages_id
  error_pages_domain_name                   = var.error_pages_domain_name
  logging_bucket_name                       = var.logging_bucket_name
  default_root                              = var.default_root
  allowed_methods                           = var.allowed_methods
  origin_path                               = var.load_balancer_path
  origin_protocol_policy                    = var.origin_protocol_policy
  origin_ssl_protocols                      = var.origin_ssl_protocols
  custom_http_whitelisted_headers           = var.custom_http_whitelisted_headers
  domain_name                               = var.load_balancer_dns_name
  min_ttl                                   = var.min_ttl
  default_ttl                               = var.default_ttl
  max_ttl                                   = var.max_ttl
  custom_error_response                     = var.custom_error_response
  project_name                              = var.project_name
}

module "cloudfront_dns" {
  providers = {
    aws = aws.east
  }

  source = "../../dns"

  alias_hostname      = split(".", var.domain_alias)[0]
  alias_netname       = trimprefix(var.domain_alias, "${split(".", var.domain_alias)[0]}.")
  alias_endpoint      = module.cloudfront_distribution.cloudfront_distribution_domain_name
  alias_endpoint_zone = module.cloudfront_distribution.cloudfront_distribution_zone
  zone_id             = var.zone_id
}
