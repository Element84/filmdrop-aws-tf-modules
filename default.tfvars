##### PROJECT VARIABLES ####
# The following variables are global to the FilmDrop infrastructure stack
environment             = "test"
project_name            = "TestProj"
domain_zone             = ""
s3_access_log_bucket    = ""
s3_logs_archive_bucket  = ""

##### NETWORKING VARIABLES ####
# If left blank, the infrastructure will try to query the values from the control tower vpc
vpc_id                    = ""
vpc_cidr                  = ""
security_group_id         = ""
public_subnets_cidr_map   = {}
private_subnets_cidr_map  = {}

##### ALARM VARIABLES ####
sns_topics_map                  = {}
cloudwatch_warning_alarms_map   = {}
cloudwatch_critical_alarms_map  = {}
sns_warning_subscriptions_map   = {}
sns_critical_subscriptions_map  = {}

##### APPLICATION VARIABLES ####
stac_server_inputs  = {
  app_name                                      = "stac_server"
  version                                       = "v3.2.0"
  domain_alias                                  = ""
  enable_transactions_extension                 = false
  collection_to_index_mappings                  = ""
  opensearch_cluster_instance_type              = "t3.small.search"
  opensearch_cluster_instance_count             = 3
  opensearch_cluster_dedicated_master_enabled   = true
  opensearch_cluster_dedicated_master_type      = "t3.small.search"
  opensearch_cluster_dedicated_master_count     = 3
  ingest_sns_topic_arns                         = []
  opensearch_ebs_volume_size                    = 35
  stac_server_and_titiler_s3_arns               = []
  web_acl_id                                    = ""
}

titiler_inputs        = {
  app_name                                      = "titiler"
  domain_alias                                  = ""
  mosaic_titiler_release_tag                    = "v0.14.0-1.0.4"
  stac_server_and_titiler_s3_arns               = []
  mosaic_titiler_waf_allowed_url                = "test.filmdrop.io"
  mosaic_titiler_host_header                    = ""
  web_acl_id                                    = ""
}

analytics_inputs      = {
  app_name                                      = "analytics"
  domain_alias                                  = ""
  jupyterhub_elb_acm_cert_arn                   = ""
  jupyterhub_elb_domain_alias                   = ""
  create_credentials                            = true
}

console_ui_inputs     = {
  app_name                                      = "console"
  domain_alias                                  = ""
  custom_error_response                         = [
    {
      error_caching_min_ttl                     = "10"
      error_code                                = "404"
      response_code                             = "200"
      response_page_path                        = "/"
    }
  ]
  filmdrop_ui_release                           = "v4.3.0"
  filmdrop_ui_config_file                       = "./profiles/console-ui/default-config/config.dev.json"
  filmdrop_ui_logo_file                         = "./profiles/console-ui/default-config/logo.png"
  filmdrop_ui_logo                              = "bm9uZQo=" # Base64: 'none'
}

cirrus_dashboard_inputs   = {
  app_name                                      = "dashboard"
  domain_alias                                  = ""
  custom_error_response                         = [
    {
      error_caching_min_ttl                     = "10"
      error_code                                = "404"
      response_code                             = "200"
      response_page_path                        = "/"
    }
  ]
  cirrus_api_endpoint_base                      = ""
  cirrus_dashboard_release                      = "v0.5.1"
}


##### INFRASTRUCTURE FLAGS ####
# To disable each flag: set to 'false'; to enable: set to 'true'
deploy_vpc                                = false
deploy_vpc_search                         = true
deploy_log_archive                        = true
deploy_alarms                             = false
deploy_stac_server_opensearch_serverless  = true
deploy_stac_server                        = true
deploy_analytics                          = true
deploy_titiler                            = true
deploy_console_ui                         = true
deploy_cirrus_dashboard                   = true
deploy_local_stac_server_artifacts        = false
deploy_sample_data_bucket                 = false


##### STAC SAMPLE DATA ####
project_sample_data_bucket_name = ""
