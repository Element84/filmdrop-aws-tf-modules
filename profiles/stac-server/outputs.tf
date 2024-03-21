output "stac_url" {
  value = local.stac_api_url
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
