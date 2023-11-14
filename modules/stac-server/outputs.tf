output "stac_server_opensearch_domain" {
  value = aws_opensearch_domain.stac_server_opensearch_domain.domain_name
}

output "stac_server_opensearch_endpoint" {
  value = aws_opensearch_domain.stac_server_opensearch_domain.endpoint
}

output "stac_server_api_domain_name" {
  value = element(
    split(
      "/",
      aws_api_gateway_deployment.stac_server_api_gateway.invoke_url,
    ),
    2,
  )
}

output "stac_server_api_path" {
  value = "/${element(
    split(
      "/",
      aws_api_gateway_deployment.stac_server_api_gateway.invoke_url,
    ),
    3,
  )}"
}

output "stac_server_opensearch_name" {
  value = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)
}
