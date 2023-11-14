output "titiler_url" {
  value = "https://${module.cloudfront_api_gateway_endpoint.domain_name}"
}
