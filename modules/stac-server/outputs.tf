output "stac_server_opensearch_domain" {
  value = aws_elasticsearch_domain.stac_server_opensearch_domain.domain_name
}

output "stac_server_opensearch_endpoint" {
  value = aws_elasticsearch_domain.stac_server_opensearch_domain.endpoint
}

