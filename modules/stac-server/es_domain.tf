resource "aws_elasticsearch_domain" "stac_server_es_domain" {
  domain_name           = "stac-server-${var.stac_api_stage}-${var.es_domain_type}"
  elasticsearch_version = var.elasticsearch_version

  cluster_config {
    instance_type             = var.es_cluster_instance_type
    instance_count            = var.es_cluster_instance_count
    dedicated_master_enabled  = var.es_cluster_dedicated_master_enabled
    zone_awareness_enabled    = var.es_cluster_zone_awareness_enabled
  }

  domain_endpoint_options {
    enforce_https = var.es_domain_enforce_https
    tls_security_policy = var.es_domain_min_tls
  }

  ebs_options {
    ebs_enabled = var.es_ebs_enabled
    volume_size = var.es_ebs_volume_size
    volume_type = var.es_ebs_volume_type
  }

  lifecycle {
      ignore_changes = [access_policies]
  }
}