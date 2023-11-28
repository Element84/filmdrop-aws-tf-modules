output "stac_url" {
  value = "https://${module.cloudfront_api_gateway_endpoint.domain_name}"
}

output "stac_opensearch_domain_name" {
  value = module.stac-server.stac_server_opensearch_domain
}

output "stac_opensearch_endpoint" {
  value = module.stac-server.stac_server_opensearch_endpoint
}
