module "stac-server" {
  source = "../../modules/stac-server"

  vpc_id                                      = var.vpc_id
  vpc_cidr_range                              = var.vpc_cidr
  vpc_subnet_ids                              = var.private_subnet_ids
  vpc_security_group_ids                      = [var.security_group_id]
  stac_api_stage                              = var.environment
  stac_id                                     = var.stac_server_inputs.stac_id
  stac_title                                  = var.stac_server_inputs.stac_title
  stac_description                            = var.stac_server_inputs.stac_description
  enable_transactions_extension               = var.stac_server_inputs.enable_transactions_extension
  enable_collections_authx                    = var.stac_server_inputs.enable_collections_authx
  enable_filter_authx                         = var.stac_server_inputs.enable_filter_authx
  enable_response_compression                 = var.stac_server_inputs.enable_response_compression
  items_max_limit                             = var.stac_server_inputs.items_max_limit
  enable_ingest_action_truncate               = var.stac_server_inputs.enable_ingest_action_truncate
  collection_to_index_mappings                = var.stac_server_inputs.collection_to_index_mappings
  opensearch_version                          = var.stac_server_inputs.opensearch_version
  opensearch_cluster_instance_type            = var.stac_server_inputs.opensearch_cluster_instance_type
  opensearch_cluster_instance_count           = var.stac_server_inputs.opensearch_cluster_instance_count
  opensearch_cluster_dedicated_master_enabled = var.stac_server_inputs.opensearch_cluster_dedicated_master_enabled
  opensearch_cluster_dedicated_master_type    = var.stac_server_inputs.opensearch_cluster_dedicated_master_type
  opensearch_cluster_dedicated_master_count   = var.stac_server_inputs.opensearch_cluster_dedicated_master_count
  opensearch_cluster_availability_zone_count  = var.stac_server_inputs.opensearch_cluster_availability_zone_count
  opensearch_ebs_volume_size                  = var.stac_server_inputs.opensearch_ebs_volume_size
  ingest_sns_topic_arns                       = var.stac_server_inputs.ingest_sns_topic_arns
  additional_ingest_sqs_senders_arns          = var.stac_server_inputs.additional_ingest_sqs_senders_arns
  api_rest_type                               = var.stac_server_inputs.api_rest_type
  api_method_authorization_type               = var.stac_server_inputs.api_method_authorization_type
  private_api_additional_security_group_ids   = var.stac_server_inputs.private_api_additional_security_group_ids
  api_lambda                                  = var.stac_server_inputs.api_lambda
  ingest_lambda                               = var.stac_server_inputs.ingest_lambda
  pre_hook_lambda                             = var.stac_server_inputs.pre_hook_lambda
  project_name                                = var.project_name
  authorized_s3_arns                          = var.stac_server_inputs.authorized_s3_arns
  deploy_stac_server_opensearch_serverless    = var.deploy_stac_server_opensearch_serverless
  deploy_stac_server_outside_vpc              = var.deploy_stac_server_outside_vpc
  private_certificate_arn                     = var.stac_server_inputs.private_certificate_arn
  domain_alias                                = var.stac_server_inputs.domain_alias

  # CloudFront or a custom domain implies the rootpath is simply "/"
  stac_api_rootpath = var.stac_server_inputs.deploy_cloudfront || var.stac_server_inputs.domain_alias != "" ? "" : "/${var.environment}"
  stac_api_url      = var.stac_server_inputs.domain_alias != "" ? "https://${var.stac_server_inputs.domain_alias}" : ""

  cors_origin      = var.stac_server_inputs.cors_origin
  cors_credentials = var.stac_server_inputs.cors_credentials
  cors_methods     = var.stac_server_inputs.cors_methods
  cors_headers     = var.stac_server_inputs.cors_headers
}

module "cloudfront_api_gateway_endpoint" {
  count  = var.stac_server_inputs.deploy_cloudfront ? 1 : 0
  source = "../../modules/cloudfront/apigw_endpoint"

  providers = {
    aws.east = aws.east
  }

  zone_id                      = var.domain_zone
  domain_alias                 = var.stac_server_inputs.domain_alias
  application_name             = var.stac_server_inputs.app_name
  api_gateway_dns_name         = module.stac-server.stac_server_api_domain_name
  api_gateway_path             = module.stac-server.stac_server_api_path
  web_acl_id                   = var.stac_server_inputs.web_acl_id == "" ? var.fd_web_acl_id : var.stac_server_inputs.web_acl_id
  project_name                 = var.project_name
  environment                  = var.environment
  create_log_bucket            = var.create_log_bucket
  log_bucket_name              = var.log_bucket_name
  log_bucket_domain_name       = var.log_bucket_domain_name
  filmdrop_archive_bucket_name = var.s3_logs_archive_bucket
  cf_function_name             = var.stac_server_inputs.auth_function.cf_function_name
  cf_function_runtime          = var.stac_server_inputs.auth_function.cf_function_runtime
  cf_function_code_path        = var.stac_server_inputs.auth_function.cf_function_code_path
  attach_cf_function           = var.stac_server_inputs.auth_function.attach_cf_function
  cf_function_event_type       = var.stac_server_inputs.auth_function.cf_function_event_type
  create_cf_function           = var.stac_server_inputs.auth_function.create_cf_function
  create_cf_basicauth_function = var.stac_server_inputs.auth_function.create_cf_basicauth_function
  cf_function_arn              = var.stac_server_inputs.auth_function.cf_function_arn
}

module "historical_ingest" {
  count  = var.stac_server_inputs.ingest.include_historical_ingest || var.stac_server_inputs.ingest.destination_collections_list != "" ? 1 : 0
  source = "../../modules/stac-server/historical-ingest"

  source_catalog_url               = var.stac_server_inputs.ingest.source_catalog_url
  destination_catalog_url          = var.stac_server_inputs.deploy_cloudfront ? "https://${module.cloudfront_api_gateway_endpoint[0].domain_name}" : "https://${module.stac-server.stac_server_api_domain_name}${module.stac-server.stac_server_api_path}"
  destination_collections_list     = var.stac_server_inputs.ingest.destination_collections_list
  destination_collections_min_lat  = var.stac_server_inputs.ingest.destination_collections_min_lat
  destination_collections_min_long = var.stac_server_inputs.ingest.destination_collections_min_long
  destination_collections_max_lat  = var.stac_server_inputs.ingest.destination_collections_max_lat
  destination_collections_max_long = var.stac_server_inputs.ingest.destination_collections_max_long
  ingest_sqs_url                   = module.stac-server.stac_server_ingest_queue_url
  date_start                       = var.stac_server_inputs.ingest.date_start
  date_end                         = var.stac_server_inputs.ingest.date_end
  include_historical_ingest        = var.stac_server_inputs.ingest.include_historical_ingest
  stac_server_name_prefix          = module.stac-server.stac_server_name_prefix
  stac_server_lambda_iam_role_arn  = module.stac-server.stac_server_lambda_iam_role_arn

  depends_on = [
    module.stac-server
  ]
}

module "ongoing_ingest" {
  count  = var.stac_server_inputs.ingest.include_ongoing_ingest ? 1 : 0
  source = "../../modules/stac-server/ongoing-ingest"

  source_sns_arn                   = var.stac_server_inputs.ingest.source_sns_arn
  ingest_sqs_arn                   = module.stac-server.stac_server_ingest_queue_arn
  destination_collections_list     = var.stac_server_inputs.ingest.destination_collections_list
  destination_collections_min_lat  = var.stac_server_inputs.ingest.destination_collections_min_lat
  destination_collections_min_long = var.stac_server_inputs.ingest.destination_collections_min_long
  destination_collections_max_lat  = var.stac_server_inputs.ingest.destination_collections_max_lat
  destination_collections_max_long = var.stac_server_inputs.ingest.destination_collections_max_long

  depends_on = [
    module.stac-server,
    module.historical_ingest # `historical_ingest` creates the collection, and without this `depends_on` a race condition can occur where the subscription for ongoing ingest can run prior to initializing the collection, leading to poorly mapped index and a bad stac-server state
  ]
}
