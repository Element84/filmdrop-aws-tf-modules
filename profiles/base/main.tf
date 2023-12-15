module "filmdrop_log_archive" {
  count  = var.deploy_log_archive ? 1 : 0
  source = "../../modules/base_infra/log_archive"

  environment  = var.environment
  project_name = var.project_name
}

module "filmdrop_vpc" {
  source = "./vpc"

  deploy_vpc               = var.deploy_vpc
  deploy_vpc_search        = var.deploy_vpc_search
  environment              = var.environment
  project_name             = var.project_name
  vpc_cidr                 = var.vpc_cidr
  vpc_id                   = var.vpc_id
  security_group_id        = var.security_group_id
  private_subnets_cidr_map = var.private_subnets_cidr_map
  public_subnets_cidr_map  = var.public_subnets_cidr_map
  archive_log_bucket_name  = var.deploy_log_archive ? module.filmdrop_log_archive[0].s3_logs_archive_bucket : var.s3_logs_archive_bucket
}

module "sns_alarm_topics" {
  count  = var.deploy_alarms ? 1 : 0
  source = "../../modules/base_infra/sns"

  sns_topics_map = var.sns_topics_map
}

module "base_warning_alarms" {
  count  = var.deploy_alarms ? 1 : 0
  source = "../../modules/base_infra/alerts"

  cloudwatch_alarms_map = var.cloudwatch_warning_alarms_map
  alarm_actions_list    = [module.sns_alarm_topics[0].sns_topic_arns["FilmDropWarning"]]
  ok_actions_list       = [module.sns_alarm_topics[0].sns_topic_arns["FilmDropWarning"]]
}

module "base_critical_alarms" {
  count  = var.deploy_alarms ? 1 : 0
  source = "../../modules/base_infra/alerts"

  cloudwatch_alarms_map = var.cloudwatch_critical_alarms_map
  alarm_actions_list    = [module.sns_alarm_topics[0].sns_topic_arns["FilmDropCritical"]]
  ok_actions_list       = [module.sns_alarm_topics[0].sns_topic_arns["FilmDropWarning"]]
}

module "sns_warning_subscriptions" {
  count  = var.deploy_alarms ? 1 : 0
  source = "../../modules/base_infra/sns_subscriptions"

  sns_topics_subscriptions_map = var.sns_warning_subscriptions_map
  sns_topic_arn                = module.sns_alarm_topics[0].sns_topic_arns["FilmDropWarning"]
}

module "sns_critical_subscriptions" {
  count  = var.deploy_alarms ? 1 : 0
  source = "../../modules/base_infra/sns_subscriptions"

  sns_topics_subscriptions_map = var.sns_critical_subscriptions_map
  sns_topic_arn                = module.sns_alarm_topics[0].sns_topic_arns["FilmDropCritical"]
}
