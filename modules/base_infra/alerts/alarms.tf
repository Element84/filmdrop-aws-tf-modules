#Add cloud watch alarms
resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarms" {
  for_each = var.cloudwatch_alarms_map

  alarm_name                = each.key
  alarm_description         = each.value.alarm_description
  comparison_operator       = each.value.comparison_operator
  evaluation_periods        = each.value.evaluation_periods
  metric_name               = each.value.metric_name
  namespace                 = each.value.metric_name
  period                    = each.value.period
  treat_missing_data        = each.value.treat_missing_data
  statistic                 = each.value.statistic
  threshold                 = each.value.threshold
  dimensions                = each.value.dimensions
  alarm_actions             = var.alarm_actions_list
  ok_actions                = var.ok_actions_list
  insufficient_data_actions = var.insufficient_data_actions_list

}
