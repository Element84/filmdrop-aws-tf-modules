module "filmdrop_log_archive" {
  count  = var.deploy_log_archive ? 1 : 0
  source = "../../modules/base_infra/log_archive"

  environment  = var.environment
  project_name = var.project_name
}

module "filmdrop_vpc" {
  source = "./vpc"

  deploy_vpc                   = var.deploy_vpc
  deploy_vpc_search            = var.deploy_vpc_search
  environment                  = var.environment
  project_name                 = var.project_name
  vpc_cidr                     = var.vpc_cidr
  vpc_id                       = var.vpc_id
  security_group_id            = var.security_group_id
  private_subnets_az_to_id_map = var.private_subnets_az_to_id_map
  public_subnets_az_to_id_map  = var.public_subnets_az_to_id_map
  archive_log_bucket_name      = var.deploy_log_archive ? module.filmdrop_log_archive[0].s3_logs_archive_bucket : var.s3_logs_archive_bucket
}

module "api_gateway_account" {
  # Create the single API Gateway account resource for setting log permissions.
  # This is only needed once per account per region with API Gateway resources
  # that need to manage logging. Having multiple within the same account and
  # region (e.g., one for both stac-server and cirrus) would lead to constant
  # state drift as Terraform will continuously switch which one is used.
  source = "../../modules/base_infra/api_gateway_account"

  environment  = var.environment
  project_name = var.project_name
}

module "sns_alarm_topics" {
  source = "../../modules/base_infra/sns"

  sns_topics_map = {
    "fd-${var.project_name}-${var.environment}-AlarmWarning"  = {}
    "fd-${var.project_name}-${var.environment}-AlarmCritical" = {}
  }
}

module "sns_warning_subscriptions" {
  source = "../../modules/base_infra/sns_subscriptions"

  sns_topics_subscriptions_map = var.sns_warning_subscriptions_map
  sns_topic_arn                = module.sns_alarm_topics.sns_topic_arns["fd-${var.project_name}-${var.environment}-AlarmWarning"]
}

module "sns_critical_subscriptions" {
  source = "../../modules/base_infra/sns_subscriptions"

  sns_topics_subscriptions_map = var.sns_critical_subscriptions_map
  sns_topic_arn                = module.sns_alarm_topics.sns_topic_arns["fd-${var.project_name}-${var.environment}-AlarmCritical"]
}

module "fd_waf_acl" {
  count  = var.deploy_waf_rule ? 1 : 0
  source = "../../modules/cloudfront/waf"

  providers = {
    aws = aws.east
  }

  logging_bucket_name = var.deploy_log_archive ? module.filmdrop_log_archive[0].s3_logs_archive_bucket : var.s3_logs_archive_bucket
  whitelist_ips       = var.whitelist_ips
  ip_blocklist        = var.ip_blocklist
  environment         = var.environment
  project_name        = var.project_name
}
