output "titiler_url" {
  value = "https://${var.titiler_inputs.deploy_cloudfront ? module.cloudfront_api_gateway_endpoint[0].domain_name : module.titiler.titiler_mosaic_api_gateway_endpoint}"
}
