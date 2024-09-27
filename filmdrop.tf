module "filmdrop" {
  source = "./profiles/core"

  providers = {
    aws.east = aws.east
    aws.main = aws.main
  }

  environment                              = var.environment
  project_name                             = var.project_name
  vpc_id                                   = var.vpc_id
  vpc_cidr                                 = var.vpc_cidr
  public_subnets_az_to_id_map              = var.public_subnets_az_to_id_map
  private_subnets_az_to_id_map             = var.private_subnets_az_to_id_map
  security_group_id                        = var.security_group_id
  sns_warning_subscriptions_map            = var.sns_warning_subscriptions_map
  sns_critical_subscriptions_map           = var.sns_critical_subscriptions_map
  s3_access_log_bucket                     = var.s3_access_log_bucket
  s3_logs_archive_bucket                   = var.s3_logs_archive_bucket
  domain_zone                              = var.domain_zone
  stac_server_inputs                       = var.stac_server_inputs
  titiler_inputs                           = var.titiler_inputs
  analytics_inputs                         = var.analytics_inputs
  console_ui_inputs                        = var.console_ui_inputs
  cirrus_inputs                            = var.cirrus_inputs
  cirrus_dashboard_inputs                  = var.cirrus_dashboard_inputs
  deploy_vpc                               = var.deploy_vpc
  deploy_vpc_search                        = var.deploy_vpc_search
  deploy_log_archive                       = var.deploy_log_archive
  deploy_stac_server                       = var.deploy_stac_server
  deploy_stac_server_opensearch_serverless = var.deploy_stac_server_opensearch_serverless
  deploy_stac_server_outside_vpc           = var.deploy_stac_server_outside_vpc
  deploy_analytics                         = var.deploy_analytics
  deploy_titiler                           = var.deploy_titiler
  deploy_console_ui                        = var.deploy_console_ui
  deploy_cirrus                            = var.deploy_cirrus
  deploy_cirrus_dashboard                  = var.deploy_cirrus_dashboard
  deploy_local_stac_server_artifacts       = var.deploy_local_stac_server_artifacts
  deploy_waf_rule                          = var.deploy_waf_rule
  ext_web_acl_id                           = var.ext_web_acl_id
  ip_blocklist                             = var.ip_blocklist
  whitelist_ips                            = var.whitelist_ips
}
