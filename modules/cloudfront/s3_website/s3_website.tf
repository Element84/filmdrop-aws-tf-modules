module "cloudfront_certificate" {
  providers = {
    aws = aws.east
  }

  source = "../../cert/"

  zone_id        = var.zone_id
  alias_address  = var.domain_alias
  dns_validation = var.dns_validation
}

module "cloudfront_distribution" {
  providers = {
    aws      = aws.east
    aws.main = aws.main
  }

  source = "../s3_origin"

  create_content_website       = var.create_content_website
  ssl_certificate_arn          = module.cloudfront_certificate.certificate_arn
  domain_aliases               = var.domain_alias == "" ? [] : [var.domain_alias]
  min_ttl                      = var.min_ttl
  default_ttl                  = var.default_ttl
  max_ttl                      = var.max_ttl
  domain_name                  = var.domain_name
  custom_error_response        = var.custom_error_response
  web_acl_id                   = var.web_acl_id
  cf_function_name             = var.cf_function_name
  cf_function_runtime          = var.cf_function_runtime
  cf_function_code_path        = var.cf_function_code_path
  attach_cf_function           = var.attach_cf_function
  cf_function_event_type       = var.cf_function_event_type
  create_cf_function           = var.create_cf_function
  create_cf_basicauth_function = var.create_cf_basicauth_function
  cf_function_arn              = var.cf_function_arn
  project_name                 = var.project_name
  environment                  = var.environment
  create_log_bucket            = var.create_log_bucket
  log_bucket_name              = var.log_bucket_name
  log_bucket_domain_name       = var.log_bucket_domain_name
  filmdrop_archive_bucket_name = var.filmdrop_archive_bucket_name
  application_name             = var.application_name
}

module "cloudfront_dns" {
  count = var.domain_alias == "" ? 0 : 1
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

moved {
  from = module.cloudfront_dns
  to   = module.cloudfront_dns[0]
}
