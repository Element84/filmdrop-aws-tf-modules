output "log_bucket" {
  value = module.cloudfront_logging.log_bucket
}

output "log_bucket_domain_name" {
  value = module.cloudfront_logging.log_bucket_domain_name
}

output "origin_id" {
  value = module.cloudfront_logging.origin_id
}

output "cloudfront_origin_access_identity_arn" {
  value = module.cloudfront_logging.cloudfront_origin_access_identity_arn
}

output "cloudfront_access_identity_path" {
  value = module.cloudfront_logging.cloudfront_access_identity_path
}

output "error_bucket" {
  value = module.cloudfront_custom_error_pages.error_bucket
}

output "error_bucket_domain_name" {
  value = module.cloudfront_custom_error_pages.error_bucket_domain_name
}

output "error_pages_id" {
  value = module.cloudfront_custom_error_pages.error_pages_id
}
