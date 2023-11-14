resource "aws_elasticsearch_domain" "stac_server_opensearch_domain" {
  domain_name           = "stac-server-${var.stac_api_stage}-${var.opensearch_domain_type}"
  elasticsearch_version = var.elasticsearch_version

  cluster_config {
    instance_type             = var.opensearch_cluster_instance_type
    instance_count            = var.opensearch_cluster_instance_count
    dedicated_master_enabled  = var.opensearch_cluster_dedicated_master_enabled
    zone_awareness_enabled    = var.opensearch_cluster_zone_awareness_enabled
  }

  domain_endpoint_options {
    enforce_https = var.opensearch_domain_enforce_https
    tls_security_policy = var.opensearch_domain_min_tls
  }

  ebs_options {
    ebs_enabled = var.opensearch_ebs_enabled
    volume_size = var.opensearch_ebs_volume_size
    volume_type = var.opensearch_ebs_volume_type
  }

  vpc_options {
    subnet_ids          = [var.vpc_subnet_ids[0], var.vpc_subnet_ids[1]]
    security_group_ids  = [aws_security_group.opensearch_security_group.id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "${var.allow_explicit_index}"
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/stac-server-${var.stac_api_stage}-${var.opensearch_domain_type}/*"
        }
    ]
}
CONFIG


  lifecycle {
      ignore_changes = [access_policies]
  }
}

resource "aws_security_group" "opensearch_security_group" {
  name        = "stac-server-${var.stac_api_stage}-${var.opensearch_domain_type}-sg"
  description = "OpenSearch Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_range]
    description = "Inbound VPC Access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound Access"
  }

  lifecycle {
      ignore_changes = [ingress, egress]
  }
}

resource "aws_iam_service_linked_role" "os" {
  count             = var.create_opensearch_service_linked_role == true ? 1 : 0
  aws_service_name  = "es.amazonaws.com"
}
