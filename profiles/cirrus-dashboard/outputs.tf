output "cirrus_dashboard_url" {
  value = "https://${var.cirrus_dashboard_inputs.deploy_cloudfront ? module.cloudfront_s3_website[0].domain_name : var.cirrus_dashboard_inputs.deploy_s3_bucket == false ? var.cirrus_dashboard_inputs.external_content_bucket.external_content_bucket_regional_domain_name : module.content_website[0].content_bucket_regional_domain_name}"
}

output "cirrus_dashboard_bucket_name" {
  value = var.cirrus_dashboard_inputs.deploy_s3_bucket == false ? var.cirrus_dashboard_inputs.external_content_bucket.external_content_website_bucket_name : var.cirrus_dashboard_inputs.deploy_cloudfront ? module.cloudfront_s3_website[0].content_bucket_name : module.content_website[0].content_bucket
}
