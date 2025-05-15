output "console_ui_url" {
  value = "https://${var.console_ui_inputs.deploy_cloudfront ? module.cloudfront_s3_website[0].domain_name : var.console_ui_inputs.deploy_s3_bucket == false ? var.console_ui_inputs.external_content_bucket.external_content_bucket_regional_domain_name : module.content_website[0].content_bucket_regional_domain_name}"
}

output "console_ui_bucket_name" {
  value = var.console_ui_inputs.deploy_s3_bucket == false ? var.console_ui_inputs.external_content_bucket.external_content_website_bucket_name : var.console_ui_inputs.deploy_cloudfront ? module.cloudfront_s3_website[0].content_bucket_name : module.content_website[0].content_bucket
}
