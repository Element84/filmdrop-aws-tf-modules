resource "aws_dynamodb_table" "cirrus_state_dynamodb_table" {
  name         = "${var.resource_prefix}-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "collections_workflow"
  range_key    = "itemids"

  attribute {
    name = "collections_workflow"
    type = "S"
  }

  attribute {
    name = "itemids"
    type = "S"
  }

  attribute {
    name = "state_updated"
    type = "S"
  }

  attribute {
    name = "updated"
    type = "S"
  }

  global_secondary_index {
    name            = "state_updated"
    hash_key        = "collections_workflow"
    range_key       = "state_updated"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "updated"
    hash_key        = "collections_workflow"
    range_key       = "updated"
    projection_type = "ALL"
  }
}

resource "aws_timestreamwrite_database" "cirrus_state_event_timestreamwrite_database" {
  database_name = "${var.resource_prefix}-state-events"
}

resource "aws_timestreamwrite_table" "cirrus_state_event_timestreamwrite_table" {
  database_name = aws_timestreamwrite_database.cirrus_state_event_timestreamwrite_database.database_name
  table_name    = "${var.resource_prefix}-state-events-table"

  retention_properties {
    magnetic_store_retention_period_in_days = var.cirrus_timestream_magnetic_store_retention_period_in_days
    memory_store_retention_period_in_hours  = var.cirrus_timestream_memory_store_retention_period_in_hours
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_state_event_system_errors_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-state DynamoDB System Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "SystemErrors"
  namespace                 = "AWS/DynamoDB"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix} Cirrus State DynamoDB System Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    TableName = aws_dynamodb_table.cirrus_state_dynamodb_table.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_state_user_errors_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-state DynamoDB User Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "UserErrors"
  namespace                 = "AWS/DynamoDB"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix} Cirrus State DynamoDB User Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    TableName = aws_dynamodb_table.cirrus_state_dynamodb_table.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_state_events_system_errors_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-state-events Timestream Events System Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "SystemErrors"
  namespace                 = "AWS/Timestream"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix} Cirrus State Timestream Events System Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    DatabaseName = aws_timestreamwrite_database.cirrus_state_event_timestreamwrite_database.database_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_state_events_user_errors_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-state-events Timestream Events User Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "UserErrors"
  namespace                 = "AWS/Timestream"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix} Cirrus State Timestream Events User Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    DatabaseName = aws_timestreamwrite_database.cirrus_state_event_timestreamwrite_database.database_name
  }
}
