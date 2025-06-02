output "stac_url" {
  value = var.stac_server_inputs.deploy_cloudfront ? "https://${module.cloudfront_api_gateway_endpoint[0].domain_name}" : "https://${module.stac-server.stac_server_api_domain_name}${module.stac-server.stac_server_api_path}"
}

output "stac_opensearch_domain_name" {
  value = module.stac-server.stac_server_opensearch_domain
}

output "stac_opensearch_endpoint" {
  value = module.stac-server.stac_server_opensearch_endpoint
}

output "stac_ingest_queue_arn" {
  value = module.stac-server.stac_server_ingest_queue_arn
}

output "stac_ingest_queue_url" {
  value = module.stac-server.stac_server_ingest_queue_url
}

output "stac_server_ingest_sns_topic_arn" {
  value = module.stac-server.stac_server_ingest_sns_topic_arn
}

output "stac_server_post_ingest_sns_topic_arn" {
  value = module.stac-server.stac_server_post_ingest_sns_topic_arn
}

output "stac_server_lambda_iam_role_arn" {
  value = module.stac-server.stac_server_lambda_iam_role_arn
}

output "stac_server_api_gateway_id" {
  value = module.stac-server.stac_server_api_gateway_id
}

output "stac_server_ingest_lambda_name" {
  value = module.stac-server.stac_server_ingest_lambda_name
}

output "stac_server_ingest_lambda_arn" {
  value = module.stac-server.stac_server_ingest_lambda_arn
}

output "stac_server_api_lambda_name" {
  value = module.stac-server.stac_server_api_lambda_name
}

output "stac_server_api_lambda_arn" {
  value = module.stac-server.stac_server_api_lambda_arn
}
