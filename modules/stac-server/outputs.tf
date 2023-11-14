output "stac_server_es_domain" {
  value = aws_elasticsearch_domain.stac_server_es_domain.domain_name
}

output "stac_server_es_endpoint" {
  value = aws_elasticsearch_domain.stac_server_es_domain.endpoint
}

