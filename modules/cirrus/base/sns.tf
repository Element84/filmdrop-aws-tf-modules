resource "aws_sns_topic" "cirrus_publish_sns_topic" {
  name = "${var.resource_prefix}-publish"
}

resource "aws_sns_topic" "cirrus_workflow_event_sns_topic" {
  name = "${var.resource_prefix}-workflow-event"
}

resource "aws_cloudwatch_metric_alarm" "cirrus_publish_sns_topic_notifications_failed_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-publish SNS Topic Notifications Failed Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "NumberOfNotificationsFailed"
  namespace                 = "AWS/SNS"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix}-publish SNS Topic Notifications Failed Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    TopicName = aws_sns_topic.cirrus_publish_sns_topic.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_workflow_event_sns_topic_notifications_failed_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-workflow-event SNS Topic Notifications Failed Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "NumberOfNotificationsFailed"
  namespace                 = "AWS/SNS"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix}-workflow-event SNS Topic Notifications Failed Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    TopicName = aws_sns_topic.cirrus_workflow_event_sns_topic.name
  }
}
