output "titiler_url" {
  value = "https://${var.filmdrop_titiler_inputs.deploy_cloudfront ? module.cloudfront_api_gateway_endpoint[0].domain_name : module.filmdrop_titiler.titiler_api_gateway_endpoint}"
}

output "titiler_vpce_dns_regional" {
  value = module.filmdrop_titiler.titiler_vpce_dns_regional
}
