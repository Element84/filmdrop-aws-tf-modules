output "content_bucket_name" {
  # value = var.create_content_website ? module.cloudfront_distribution.content_bucket_name : ""
  value = module.cloudfront_distribution.content_bucket_name
}

output "domain_name" {
  value = var.domain_alias == "" ? module.cloudfront_distribution.cloudfront_distribution_domain_name : var.domain_alias
}
