output "domain_name" {
  value = var.domain_alias == "" ? module.cloudfront_distribution.cloudfront_distribution_domain_name : var.domain_alias
}

output "cloudfront_domain_origin_param" {
  value = module.cloudfront_distribution.cloudfront_domain_origin_param
}
