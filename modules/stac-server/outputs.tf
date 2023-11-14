output "stac_server_os_domain" {
  value = aws_elasticsearch_domain.stac_server_os_domain.domain_name
}

output "stac_server_os_endpoint" {
  value = aws_elasticsearch_domain.stac_server_os_domain.endpoint
}

