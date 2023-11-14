output "cloudfront_origin_access_identity_arn" {
  value = module.cloudfront_distribution.cloudfront_origin_access_identity_arn
}

output "cloudfront_access_identity_path" {
  value = module.cloudfront_distribution.cloudfront_access_identity_path
}

output "cloudfront_distribution_id" {
  value = module.cloudfront_distribution.cloudfront_distribution_id
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront_distribution.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_arn" {
  value = module.cloudfront_distribution.cloudfront_distribution_arn
}

output "cloudfront_distribution_zone" {
  value = module.cloudfront_distribution.cloudfront_distribution_zone
}

output "domain_name" {
  value = var.domain_alias == "" ? module.cloudfront_distribution.cloudfront_distribution_domain_name : var.domain_alias
}

output "cloudfront_domain_origin_param" {
  value = module.cloudfront_distribution.cloudfront_domain_origin_param
}
