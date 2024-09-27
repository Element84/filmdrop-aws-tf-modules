module "custom_warning_alarms" {
  count  = var.deploy_alarms ? 1 : 0
  source = "../base_infra/alerts"

  cloudwatch_alarms_map = var.custom_cloudwatch_warning_alarms_map
  alarm_actions_list    = [var.critical_sns_topic_arn]
  ok_actions_list       = [var.warning_sns_topic_arn]
}

module "custom_critical_alarms" {
  count  = var.deploy_alarms ? 1 : 0
  source = "../base_infra/alerts"

  cloudwatch_alarms_map = var.custom_cloudwatch_critical_alarms_map
  alarm_actions_list    = [var.critical_sns_topic_arn]
  ok_actions_list       = [var.warning_sns_topic_arn]
}
