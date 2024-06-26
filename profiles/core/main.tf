module "base_infra" {
  source = "../base"

  deploy_vpc                     = var.deploy_vpc
  deploy_vpc_search              = var.deploy_vpc_search
  deploy_alarms                  = var.deploy_alarms
  deploy_log_archive             = var.deploy_log_archive
  environment                    = var.environment
  project_name                   = var.project_name
  vpc_cidr                       = var.vpc_cidr
  vpc_id                         = var.vpc_id
  sns_topics_map                 = var.sns_topics_map
  security_group_id              = var.security_group_id
  private_subnets_az_to_id_map   = var.private_subnets_az_to_id_map
  public_subnets_az_to_id_map    = var.public_subnets_az_to_id_map
  cloudwatch_warning_alarms_map  = var.cloudwatch_warning_alarms_map
  cloudwatch_critical_alarms_map = var.cloudwatch_critical_alarms_map
  sns_warning_subscriptions_map  = var.sns_warning_subscriptions_map
  sns_critical_subscriptions_map = var.sns_critical_subscriptions_map
  s3_access_log_bucket           = var.s3_access_log_bucket
  s3_logs_archive_bucket         = var.s3_logs_archive_bucket
}

# Run setup scripts
module "setup" {
  source = "../setup"

  stac_server_version                = var.stac_server_inputs.version
  deploy_local_stac_server_artifacts = var.deploy_local_stac_server_artifacts
}

module "stac-server" {
  count  = var.deploy_stac_server ? 1 : 0
  source = "../stac-server"

  providers = {
    aws.east = aws.east
  }

  vpc_id                                   = module.base_infra.vpc_id
  private_subnet_ids                       = module.base_infra.private_subnet_ids
  security_group_id                        = module.base_infra.security_group_id
  vpc_cidr                                 = module.base_infra.vpc_cidr
  environment                              = var.environment
  stac_server_inputs                       = var.stac_server_inputs
  project_name                             = var.project_name
  s3_logs_archive_bucket                   = module.base_infra.s3_logs_archive_bucket
  domain_zone                              = var.domain_zone
  deploy_stac_server_opensearch_serverless = var.deploy_stac_server_opensearch_serverless
  deploy_stac_server_outside_vpc           = var.deploy_stac_server_outside_vpc

  depends_on = [
    module.setup
  ]
}

module "titiler" {
  count  = var.deploy_titiler ? 1 : 0
  source = "../titiler"

  providers = {
    aws.east = aws.east
  }

  project_name           = var.project_name
  environment            = var.environment
  titiler_inputs         = var.titiler_inputs
  stac_url               = var.deploy_stac_server ? module.stac-server[0].stac_url : ""
  s3_logs_archive_bucket = module.base_infra.s3_logs_archive_bucket
  domain_zone            = var.domain_zone
  private_subnet_ids     = module.base_infra.private_subnet_ids
  security_group_id      = module.base_infra.security_group_id
}

module "analytics" {
  count  = var.deploy_analytics ? 1 : 0
  source = "../analytics"

  providers = {
    aws.east = aws.east
  }

  vpc_id                     = module.base_infra.vpc_id
  private_subnet_ids         = module.base_infra.private_subnet_ids
  security_group_id          = module.base_infra.security_group_id
  vpc_cidr                   = module.base_infra.vpc_cidr
  public_subnet_ids          = module.base_infra.public_subnet_ids
  private_availability_zones = module.base_infra.private_avaliability_zones
  public_availability_zones  = module.base_infra.public_avaliability_zones
  s3_logs_archive_bucket     = module.base_infra.s3_logs_archive_bucket
  project_name               = var.project_name
  environment                = var.environment
  domain_zone                = var.domain_zone
  analytics_inputs           = var.analytics_inputs
}

module "console-ui" {
  count  = var.deploy_console_ui ? 1 : 0
  source = "../console-ui"

  providers = {
    aws.east = aws.east
    aws.main = aws.main
  }

  vpc_id                 = module.base_infra.vpc_id
  private_subnet_ids     = module.base_infra.private_subnet_ids
  security_group_id      = module.base_infra.security_group_id
  project_name           = var.project_name
  environment            = var.environment
  console_ui_inputs      = var.console_ui_inputs
  domain_zone            = var.domain_zone
  s3_logs_archive_bucket = module.base_infra.s3_logs_archive_bucket
}

module "cirrus" {
  count  = var.deploy_cirrus ? 1 : 0
  source = "../cirrus"

  project_name  = var.project_name
  environment   = var.environment
  cirrus_inputs = var.cirrus_inputs
}

module "cirrus-dashboard" {
  count  = var.deploy_cirrus_dashboard ? 1 : 0
  source = "../cirrus-dashboard"

  providers = {
    aws.east = aws.east
    aws.main = aws.main
  }

  vpc_id                  = module.base_infra.vpc_id
  private_subnet_ids      = module.base_infra.private_subnet_ids
  security_group_id       = module.base_infra.security_group_id
  project_name            = var.project_name
  environment             = var.environment
  s3_logs_archive_bucket  = module.base_infra.s3_logs_archive_bucket
  domain_zone             = var.domain_zone
  cirrus_dashboard_inputs = var.cirrus_dashboard_inputs
}