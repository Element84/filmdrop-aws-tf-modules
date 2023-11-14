module "stac-server" {
  source = "../../modules/stac-server"

  vpc_id                                      = var.vpc_id
  vpc_cidr_range                              = var.vpc_cidr
  vpc_subnet_ids                              = var.private_subnet_ids
  vpc_security_group_ids                      = [var.security_group_id]
  stac_api_stage                              = var.environment
  enable_transactions_extension               = var.stac_server_inputs.enable_transactions_extension
  collection_to_index_mappings                = var.stac_server_inputs.collection_to_index_mappings
  opensearch_cluster_instance_type            = var.stac_server_inputs.opensearch_cluster_instance_type
  opensearch_cluster_instance_count           = var.stac_server_inputs.opensearch_cluster_instance_count
  opensearch_cluster_dedicated_master_enabled = var.stac_server_inputs.opensearch_cluster_dedicated_master_enabled
  opensearch_cluster_dedicated_master_type    = var.stac_server_inputs.opensearch_cluster_dedicated_master_type
  opensearch_cluster_dedicated_master_count   = var.stac_server_inputs.opensearch_cluster_dedicated_master_count
  ingest_sns_topic_arns                       = var.stac_server_inputs.ingest_sns_topic_arns
  opensearch_ebs_volume_size                  = var.stac_server_inputs.opensearch_ebs_volume_size
  project_name                                = var.project_name
  stac_server_s3_bucket_arns                  = var.stac_server_inputs.stac_server_and_titiler_s3_arns
}

module "cloudfront_api_gateway_endpoint" {
  source = "../../modules/cloudfront/apigw_endpoint"

  providers = {
    aws.east = aws.east
  }

  zone_id                       = var.domain_zone
  domain_alias                  = var.stac_server_inputs.domain_alias
  application_name              = var.stac_server_inputs.app_name
  api_gateway_dns_name          = module.stac-server.stac_server_api_domain_name
  api_gateway_path              = module.stac-server.stac_server_api_path
  web_acl_id                    = var.stac_server_inputs.web_acl_id
  project_name                  = var.project_name
  environment                   = var.environment
  create_log_bucket             = var.create_log_bucket
  log_bucket_name               = var.log_bucket_name
  log_bucket_domain_name        = var.log_bucket_domain_name
  filmdrop_archive_bucket_name  = var.s3_logs_archive_bucket
}

