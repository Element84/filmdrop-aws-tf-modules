module "filmdrop" {
  source = "./profiles/core"

  providers = {
    aws.east = aws.east
    aws.main = aws.main
  }

  environment                               = var.environment
  project_name                              = var.project_name
  vpc_id                                    = var.vpc_id
  vpc_cidr                                  = var.vpc_cidr
  public_subnets_cidr_map                   = var.public_subnets_cidr_map
  private_subnets_cidr_map                  = var.private_subnets_cidr_map
  security_group_id                         = var.security_group_id
  sns_topics_map                            = var.sns_topics_map
  cloudwatch_warning_alarms_map             = var.cloudwatch_warning_alarms_map
  cloudwatch_critical_alarms_map            = var.cloudwatch_critical_alarms_map
  sns_warning_subscriptions_map             = var.sns_warning_subscriptions_map
  sns_critical_subscriptions_map            = var.sns_critical_subscriptions_map
  s3_access_log_bucket                      = var.s3_access_log_bucket
  s3_logs_archive_bucket                    = var.s3_logs_archive_bucket
  domain_zone                               = var.domain_zone
  stac_server_inputs                        = var.stac_server_inputs
  titiler_inputs                            = var.titiler_inputs
  analytics_inputs                          = var.analytics_inputs
  console_ui_inputs                         = var.console_ui_inputs
  cirrus_dashboard_inputs                   = var.cirrus_dashboard_inputs
  deploy_vpc                                = var.deploy_vpc
  deploy_vpc_search                         = var.deploy_vpc_search
  deploy_log_archive                        = var.deploy_log_archive
  deploy_alarms                             = var.deploy_alarms
  deploy_stac_server                        = var.deploy_stac_server
  deploy_stac_server_opensearch_serverless  = var.deploy_stac_server_opensearch_serverless
  skip_deploy_stac_server_cloudfront        = var.skip_deploy_stac_server_cloudfront
  deploy_analytics                          = var.deploy_analytics
  deploy_titiler                            = var.deploy_titiler
  deploy_console_ui                         = var.deploy_console_ui
  deploy_cirrus_dashboard                   = var.deploy_cirrus_dashboard
  deploy_local_stac_server_artifacts        = var.deploy_local_stac_server_artifacts
  deploy_sample_data_bucket                 = var.deploy_sample_data_bucket
  project_sample_data_bucket_name           = var.project_sample_data_bucket_name
}
