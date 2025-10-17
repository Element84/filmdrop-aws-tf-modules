locals {
  # If we're not creating at least one s3 or SNS trigger, some resources below can use this to skip creation. Note
  # that we do create the queue and its DLQ, as the user may be configuring the queue first and later adding triggers
  at_least_one_trigger = (var.feeder_config.triggers_s3 != null || var.feeder_config.triggers_sns != null)
}

# The feeder SQS queue, and its DLQ
resource "aws_sqs_queue" "feeder_queue" {
  name = local.name_main

  # Users may rarely want/need to change default sqs values, so we make it optional field in feeder definition.yaml
  # Thus, try is needed for these values, as .sqs may be undefined. null results in using the default value, which
  # matches the behavior of other modules in this repo
  delay_seconds              = try(var.feeder_config.sqs.delay_seconds, null)
  max_message_size           = try(var.feeder_config.sqs.max_message_size, null)
  message_retention_seconds  = try(var.feeder_config.sqs.message_retention_seconds, null)
  receive_wait_time_seconds  = try(var.feeder_config.sqs.receive_wait_time_seconds, null)
  visibility_timeout_seconds = try(var.feeder_config.sqs.visibility_timeout_seconds, null)
}

resource "aws_sqs_queue_redrive_policy" "feeder_queue_redrive_policy" {
  queue_url = aws_sqs_queue.feeder_queue.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.feeder_queue_dlq.arn
    maxReceiveCount     = try(var.feeder_config.sqs.max_receive_count, 5)
  })
}

resource "aws_sqs_queue" "feeder_queue_dlq" {
  name = "${local.name_main}-dlq"
}

resource "aws_sqs_queue_redrive_allow_policy" "feeder_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.feeder_queue_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.feeder_queue.arn]
  })
}

# Grant each S3 bucket and SNS topic permissions to send messages to the feeder queue
data "aws_iam_policy_document" "sqs_access" {
  # If the user hasn't yet defined any triggers at all, don't create this policy
  count = local.at_least_one_trigger ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.feeder_queue.arn]

    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com",
        "s3.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = concat(
        [for b in coalesce(var.feeder_config.triggers_s3, []) : b.bucket_arn],
        [for t in coalesce(var.feeder_config.triggers_sns, []) : t.topic_arn]
      )
    }
  }
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  # If the user hasn't yet defined any triggers at all, don't create this policy
  count = local.at_least_one_trigger ? 1 : 0

  queue_url = aws_sqs_queue.feeder_queue.url
  policy    = data.aws_iam_policy_document.sqs_access[0].json
}
