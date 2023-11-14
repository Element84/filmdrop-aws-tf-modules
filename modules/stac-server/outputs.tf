output "stac_server_opensearch_domain" {
  value = aws_opensearch_domain.stac_server_opensearch_domain.domain_name
}

output "stac_server_opensearch_endpoint" {
  value = aws_opensearch_domain.stac_server_opensearch_domain.endpoint
}

