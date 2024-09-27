resource "aws_sqs_queue" "cirrus_process_sqs_queue" {
  name                       = "${var.cirrus_prefix}-process"
  visibility_timeout_seconds = var.cirrus_process_sqs_timeout

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.cirrus_process_dead_letter_sqs_queue.arn
    maxReceiveCount     = var.cirrus_process_sqs_max_receive_count
  })
}

resource "aws_sqs_queue" "cirrus_process_dead_letter_sqs_queue" {
  name = "${var.cirrus_prefix}-process-dead-letter"
}

resource "aws_sqs_queue" "cirrus_update_state_dead_letter_sqs_queue" {
  name = "${var.cirrus_prefix}-update-state-dead-letter"
}

resource "aws_cloudwatch_metric_alarm" "cirrus_update_state_dead_letter_sqs_queue_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.cirrus_prefix}-update-state-dead-letter SQS DLQ Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "ApproximateNumberOfMessagesVisible"
  namespace                 = "AWS/SQS"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.cirrus_prefix}-update-state-dead-letter DLQ Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    QueueName = aws_sqs_queue.cirrus_update_state_dead_letter_sqs_queue.name
  }
}
