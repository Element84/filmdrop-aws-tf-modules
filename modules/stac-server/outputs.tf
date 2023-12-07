output "stac_server_opensearch_domain" {
  value = local.opensearch_domain
}

output "stac_server_opensearch_endpoint" {
  value = local.opensearch_endpoint
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

output "stac_server_ingest_queue_arn" {
  value = aws_sqs_queue.stac_server_ingest_sqs_queue.arn
}
