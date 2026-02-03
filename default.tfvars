##### PROJECT VARIABLES ####
# The following variables are global to the FilmDrop infrastructure stack
project_name           = "TestProj"
environment            = "test"
domain_zone            = ""
s3_access_log_bucket   = ""
s3_logs_archive_bucket = ""

##### NETWORKING VARIABLES ####
# If left blank, the infrastructure will try to query the values from the control tower vpc
vpc_id                       = ""
vpc_cidr                     = ""
security_group_id            = ""
public_subnets_az_to_id_map  = {}
private_subnets_az_to_id_map = {}

##### ALARM VARIABLES ####
sns_warning_subscriptions_map  = {}
sns_critical_subscriptions_map = {}

##### APPLICATION VARIABLES ####
stac_server_inputs = {
  app_name                      = "stac_server"
  version                       = null
  stac_id                       = "stac-server"
  stac_title                    = "STAC API"
  stac_description              = "A STAC API using stac-server"
  api_rest_type                 = "REGIONAL"
  api_method_authorization_type = "NONE"
  api_provisioned_concurrency   = 0
  deploy_cloudfront             = false
  web_acl_id                    = ""
  domain_alias                  = ""
  enable_transactions_extension = false
  enable_collections_authx      = false
  enable_filter_authx           = false
  enable_response_compression   = true
  items_max_limit               = 100
  enable_ingest_action_truncate = false
  collection_to_index_mappings  = ""
  opensearch_version            = "OpenSearch_2.19"

  # smallest instance/cluster size option, appropriate for only for test environments
  opensearch_cluster_instance_type           = "t3.small.search"
  opensearch_cluster_instance_count          = 1
  opensearch_cluster_zone_awareness_enabled  = false
  opensearch_cluster_availability_zone_count = 1

  opensearch_cluster_dedicated_master_enabled = false
  opensearch_cluster_dedicated_master_type    = "t3.small.search"
  opensearch_cluster_dedicated_master_count   = 3

  opensearch_ebs_volume_size                = 35
  opensearch_override_main_response_version = null
  ingest_sns_topic_arns                     = []
  additional_ingest_sqs_senders_arns        = []
  cors_origin                               = "*"
  cors_credentials                          = false
  cors_methods                              = ""
  cors_headers                              = ""
  authorized_s3_arns                        = []
  private_api_additional_security_group_ids = null
  api_lambda                                = null
  ingest_lambda                             = null
  pre_hook_lambda                           = null
  private_certificate_arn                   = ""
  vpce_private_dns_enabled                  = false
  custom_vpce_id                            = null
  auth_function = {
    cf_function_name             = ""
    cf_function_runtime          = "cloudfront-js-2.0"
    cf_function_code_path        = ""
    attach_cf_function           = false
    cf_function_event_type       = "viewer-request"
    create_cf_function           = false
    create_cf_basicauth_function = false
    cf_function_arn              = ""
  }
  ingest = {
    source_catalog_url               = ""
    destination_collections_list     = ""
    destination_collections_min_lat  = -90
    destination_collections_min_long = -180
    destination_collections_max_lat  = 90
    destination_collections_max_long = 180
    date_start                       = ""
    date_end                         = ""
    include_historical_ingest        = false
    source_sns_arn                   = ""
    include_ongoing_ingest           = false
  }
}

titiler_inputs = {
  app_name                                  = "titiler"
  domain_alias                              = ""
  deploy_cloudfront                         = false
  version                                   = "v0.14.0-1.0.5"
  authorized_s3_arns                        = []
  mosaic_titiler_waf_allowed_url            = "test.filmdrop.io"
  mosaic_titiler_host_header                = ""
  mosaic_tile_timeout                       = 30
  web_acl_id                                = ""
  is_private_endpoint                       = false
  api_method_authorization_type             = "NONE"
  api_provisioned_concurrency               = 0
  private_certificate_arn                   = ""
  vpce_private_dns_enabled                  = false
  custom_vpce_id                            = null
  private_api_additional_security_group_ids = null
  allowed_extensions_enabled                = true
  auth_function = {
    cf_function_name             = ""
    cf_function_runtime          = "cloudfront-js-2.0"
    cf_function_code_path        = ""
    attach_cf_function           = false
    cf_function_event_type       = "viewer-request"
    create_cf_function           = false
    create_cf_basicauth_function = false
    cf_function_arn              = ""
  }
}

filmdrop_titiler_inputs = {
  app_name                                  = "fd-titi"
  domain_alias                              = ""
  deploy_cloudfront                         = true
  version                                   = "v0.1.1"
  authorized_s3_arns                        = ["arn:aws:s3:::fd-moose-dev-catalog"]
  titiler_waf_allowed_url                   = "test.filmdrop_titiler.io"
  titiler_host_header                       = ""
  mosaic_tile_timeout                       = 30
  web_acl_id                                = ""
  is_private_endpoint                       = false
  api_method_authorization_type             = "NONE"
  api_provisioned_concurrency               = 0
  private_certificate_arn                   = ""
  vpce_private_dns_enabled                  = false
  custom_vpce_id                            = null
  private_api_additional_security_group_ids = null
  allowed_extensions_enabled                = true
  auth_function = {
    cf_function_name             = ""
    cf_function_runtime          = "cloudfront-js-2.0"
    cf_function_code_path        = ""
    attach_cf_function           = false
    cf_function_event_type       = "viewer-request"
    create_cf_function           = false
    create_cf_basicauth_function = false
    cf_function_arn              = ""
  }
}

analytics_inputs = {
  app_name                    = "analytics"
  domain_alias                = ""
  jupyterhub_elb_acm_cert_arn = ""
  jupyterhub_elb_domain_alias = ""
  create_credentials          = true
  web_acl_id                  = ""
  auth_function = {
    cf_function_name             = ""
    cf_function_runtime          = "cloudfront-js-2.0"
    cf_function_code_path        = ""
    attach_cf_function           = false
    cf_function_event_type       = "viewer-request"
    create_cf_function           = false
    create_cf_basicauth_function = false
    cf_function_arn              = ""
  }

  cleanup = {
    enabled                            = false
    asg_min_capacity                   = 1
    analytics_node_limit               = 4
    notifications_schedule_expressions = []
    cleanup_schedule_expressions       = []
  }

  eks = {
    cluster_version    = "1.32"
    autoscaler_version = "v1.32.0"
  }
}

filmdrop_ui_inputs = {
  app_name          = "console"
  domain_alias      = ""
  deploy_cloudfront = true
  deploy_s3_bucket  = true
  external_content_bucket = {
    external_content_website_bucket_name         = ""
    external_content_bucket_regional_domain_name = ""
  }
  web_acl_id              = ""
  version                 = "v5.3.0"
  filmdrop_ui_config_file = "./profiles/filmdrop-ui/default-config/config.dev.json"
  filmdrop_ui_logo_file   = "./profiles/filmdrop-ui/default-config/logo.png"
  filmdrop_ui_logo        = "bm9uZQo=" # Base64: 'none'

  custom_error_response = [
    {
      error_caching_min_ttl = "10"
      error_code            = "404"
      response_code         = "200"
      response_page_path    = "/"
    }
  ]

  auth_function = {
    cf_function_name             = ""
    cf_function_runtime          = "cloudfront-js-2.0"
    cf_function_code_path        = ""
    attach_cf_function           = false
    cf_function_event_type       = "viewer-request"
    create_cf_function           = false
    create_cf_basicauth_function = false
    cf_function_arn              = ""
  }
}

cirrus_inputs = {
  data_bucket                               = "" # If left blank the deployment will create the data bucket
  payload_bucket                            = "" # If left blank the deployment will create the payload bucket
  log_level                                 = "DEBUG"
  deploy_alarms                             = false
  deploy_api                                = true
  private_api_additional_security_group_ids = null
  private_certificate_arn                   = ""
  domain_alias                              = ""
  custom_alarms = {
    warning  = {}
    critical = {}
  }
  process = {
    sqs_timeout                   = 180
    sqs_max_receive_count         = 5
    sqs_cross_account_sender_arns = []
  }
  state = {
    timestream_magnetic_store_retention_period_in_days = 93
    timestream_memory_store_retention_period_in_hours  = 24
  }
  lambda_version      = null
  lambda_zip_filepath = null
  lambda_pyversion    = null
  api_settings = {
    lbd_timeout                 = 10
    lbd_memory                  = 512
    lbd_provisioned_concurrency = 0
    gateway_rest_type           = "EDGE"
  }
  process_lambda = {
    timeout              = 10
    memory               = 512
    reserved_concurrency = 16
  }
  update_state_lambda = {
    timeout = 15
    memory  = 512
  }
  pre_batch_lambda = {
    timeout = 15
    memory  = 512
  }
  post_batch_lambda = {
    timeout = 15
    memory  = 512
  }
  feeder_definitions_dir                       = null
  task_batch_compute_definitions_dir           = null
  task_batch_compute_definitions_variables     = null
  task_batch_compute_definitions_variables_ssm = null
  task_definitions_dir                         = null
  task_definitions_variables                   = null
  task_definitions_variables_ssm               = null
  workflow_definitions_dir                     = null
  workflow_definitions_variables               = null
  workflow_definitions_variables_ssm           = null
  workflow_metrics_cloudwatch_enabled          = true
  workflow_metrics_timestream_enabled          = true
}

cirrus_dashboard_inputs = {
  app_name          = "dashboard"
  domain_alias      = ""
  deploy_cloudfront = true
  deploy_s3_bucket  = true
  external_content_bucket = {
    external_content_website_bucket_name         = ""
    external_content_bucket_regional_domain_name = ""
  }
  web_acl_id           = ""
  version              = "v0.5.1"
  cirrus_api_endpoint  = ""
  metrics_api_endpoint = ""
  custom_error_response = [
    {
      error_caching_min_ttl = "10"
      error_code            = "404"
      response_code         = "200"
      response_page_path    = "/"
    }
  ]
  auth_function = {
    cf_function_name             = ""
    cf_function_runtime          = "cloudfront-js-2.0"
    cf_function_code_path        = ""
    attach_cf_function           = false
    cf_function_event_type       = "viewer-request"
    create_cf_function           = false
    create_cf_basicauth_function = false
    cf_function_arn              = ""
  }
}


##### INFRASTRUCTURE FLAGS ####
# Only one of these should ever be true. Note that deploy_vpc_search relies on specific tagging/naming schemes in
# regards to your VPC and subnets
deploy_vpc_search = true
deploy_vpc        = false

# stac-server can either be deployed in managed or serverless mode. To deploy in managed mode, set deploy_stac_server
# = true, leave the serverless flag = false. To deploy in serverless mode, set both to true
deploy_stac_server                       = false
deploy_stac_server_opensearch_serverless = false
deploy_stac_server_outside_vpc           = false
deploy_local_stac_server_artifacts       = false

deploy_cirrus           = false
deploy_cirrus_dashboard = false
deploy_titiler          = false
deploy_filmdrop_titiler = true
deploy_log_archive      = true
deploy_analytics        = false
deploy_filmdrop_ui      = false
deploy_waf_rule         = false


#### WAF Rule Settings
ext_web_acl_id = "" # Specify if bringing an externally managed WAF
ip_blocklist   = []
whitelist_ips  = []
