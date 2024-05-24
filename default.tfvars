##### PROJECT VARIABLES ####
# The following variables are global to the FilmDrop infrastructure stack
environment            = "test"
project_name           = "TestProj"
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
sns_topics_map                 = {}
cloudwatch_warning_alarms_map  = {}
cloudwatch_critical_alarms_map = {}
sns_warning_subscriptions_map  = {}
sns_critical_subscriptions_map = {}

##### APPLICATION VARIABLES ####
stac_server_inputs = {
  app_name                                    = "stac_server"
  version                                     = "v3.7.0"
  deploy_cloudfront                           = true
  domain_alias                                = ""
  enable_transactions_extension               = false
  collection_to_index_mappings                = ""
  opensearch_cluster_instance_type            = "t3.small.search"
  opensearch_cluster_instance_count           = 3
  opensearch_cluster_dedicated_master_enabled = true
  opensearch_cluster_dedicated_master_type    = "t3.small.search"
  opensearch_cluster_dedicated_master_count   = 3
  ingest_sns_topic_arns                       = []
  additional_ingest_sqs_senders_arns          = []
  opensearch_ebs_volume_size                  = 35
  cors_origin                                 = "*"
  cors_credentials                            = false
  cors_methods                                = ""
  cors_headers                                = ""
  authorized_s3_arns                          = []
  web_acl_id                                  = ""
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
  app_name                       = "titiler"
  domain_alias                   = ""
  deploy_cloudfront              = true
  version                        = "v0.14.0-1.0.4"
  authorized_s3_arns             = []
  mosaic_titiler_waf_allowed_url = "test.filmdrop.io"
  mosaic_titiler_host_header     = ""
  web_acl_id                     = ""
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
    cluster_version    = "1.29"
    autoscaler_version = "v1.29.0"
  }
}

console_ui_inputs = {
  app_name                = "console"
  domain_alias            = ""
  deploy_cloudfront       = true
  version                 = "v5.3.0"
  filmdrop_ui_config_file = "./profiles/console-ui/default-config/config.dev.json"
  filmdrop_ui_logo_file   = "./profiles/console-ui/default-config/logo.png"
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
  data_bucket    = "cirrus-data-bucket-name"
  payload_bucket = "cirrus-payload-bucket-name"
  process = {
    sqs_timeout           = 180
    sqs_max_receive_count = 5
  }
  state = {
    timestream_magnetic_store_retention_period_in_days = 93
    timestream_memory_store_retention_period_in_hours  = 24
  }
}

cirrus_dashboard_inputs = {
  app_name             = "dashboard"
  domain_alias         = ""
  deploy_cloudfront    = true
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
# To disable each flag: set to 'false'; to enable: set to 'true'
deploy_vpc                               = false
deploy_vpc_search                        = true
deploy_log_archive                       = true
deploy_alarms                            = false
deploy_stac_server_opensearch_serverless = false
deploy_stac_server                       = true
deploy_stac_server_outside_vpc           = false
deploy_analytics                         = true
deploy_titiler                           = true
deploy_console_ui                        = true
deploy_cirrus                            = true
deploy_cirrus_dashboard                  = true
deploy_local_stac_server_artifacts       = false
