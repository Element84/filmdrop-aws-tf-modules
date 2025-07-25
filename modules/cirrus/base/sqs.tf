data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "cirrus_process_sqs_queue" {
  name                       = "${var.resource_prefix}-process"
  visibility_timeout_seconds = var.cirrus_process_sqs_timeout

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.cirrus_process_dead_letter_sqs_queue.arn
    maxReceiveCount     = var.cirrus_process_sqs_max_receive_count
  })
}

locals {
  enable_cross_account_policy = length(var.cirrus_process_sqs_cross_account_sender_arns) > 0

  process_sqs_policy = local.enable_cross_account_policy ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCurrentAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "sqs:*"
        Resource = aws_sqs_queue.cirrus_process_sqs_queue.arn
      },
      {
        Sid    = "AllowCrossAccountSenders"
        Effect = "Allow"
        Principal = {
          AWS = var.cirrus_process_sqs_cross_account_sender_arns
        }
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.cirrus_process_sqs_queue.arn
      }
    ]
  }) : null
}

resource "aws_sqs_queue_policy" "cirrus_process_sqs_queue_policy" {
  count     = local.enable_cross_account_policy ? 1 : 0
  queue_url = aws_sqs_queue.cirrus_process_sqs_queue.id
  policy    = local.process_sqs_policy
}

resource "aws_sqs_queue" "cirrus_process_dead_letter_sqs_queue" {
  name = "${var.resource_prefix}-process-dead-letter"
}

resource "aws_sqs_queue" "cirrus_update_state_dead_letter_sqs_queue" {
  name = "${var.resource_prefix}-update-state-dead-letter"
}

resource "aws_cloudwatch_metric_alarm" "cirrus_update_state_dead_letter_sqs_queue_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-update-state-dead-letter SQS DLQ Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "ApproximateNumberOfMessagesVisible"
  namespace                 = "AWS/SQS"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix}-update-state-dead-letter DLQ Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    QueueName = aws_sqs_queue.cirrus_update_state_dead_letter_sqs_queue.name
  }
}
