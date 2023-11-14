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
    aws.main    = aws.main
  }

  source = "../s3"

  create_content_website                    = var.create_content_website
  create_waf_rule                           = true
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
  min_ttl                                   = var.min_ttl
  default_ttl                               = var.default_ttl
  max_ttl                                   = var.max_ttl
  domain_name                               = var.domain_name
  custom_error_response                     = var.custom_error_response
  
  attach_cf_function                        = var.attach_cf_function
  cf_function_name                          = var.cf_function_name
  cf_function_runtime                       = var.cf_function_runtime
  cf_function_code_path                     = var.cf_function_code_path
  cf_function_event_type                    = var.cf_function_event_type
  create_cf_function                        = var.create_cf_function
  cf_function_arn                           = var.cf_function_arn
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
