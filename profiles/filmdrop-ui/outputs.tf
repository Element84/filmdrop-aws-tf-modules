output "filmdrop_ui_url" {
  value = "https://${var.filmdrop_ui_inputs.deploy_cloudfront ? module.cloudfront_s3_website[0].domain_name : var.filmdrop_ui_inputs.deploy_s3_bucket == false ? var.filmdrop_ui_inputs.external_content_bucket.external_content_bucket_regional_domain_name : module.content_website[0].content_bucket_regional_domain_name}"
}

output "filmdrop_ui_bucket_name" {
  value = var.filmdrop_ui_inputs.deploy_s3_bucket == false ? var.filmdrop_ui_inputs.external_content_bucket.external_content_website_bucket_name : var.filmdrop_ui_inputs.deploy_cloudfront ? module.cloudfront_s3_website[0].content_bucket_name : module.content_website[0].content_bucket
}
