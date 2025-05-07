locals {
  role_arns = [for item in var.additional_ingest_sqs_senders_arns : item if length(regexall("^arn:[a-z-]+:iam::\\d{12}:role", item)) > 0]

  non_role_arns = concat(
    [aws_sns_topic.stac_server_ingest_sns_topic.arn],
    var.ingest_sns_topic_arns,
    [for item in var.additional_ingest_sqs_senders_arns : item if !contains(local.role_arns, item)]
  )
}

resource "aws_lambda_function" "stac_server_ingest" {
  filename                       = local.resolved_ingest_lambda_zip_filepath
  function_name                  = "${local.name_prefix}-stac-server-ingest"
  description                    = "stac-server Ingest Lambda"
  role                           = aws_iam_role.stac_api_lambda_role.arn
  handler                        = var.ingest_lambda.handler
  source_code_hash               = filebase64sha256(local.resolved_ingest_lambda_zip_filepath)
  runtime                        = var.ingest_lambda.runtime
  timeout                        = var.ingest_lambda.timeout_seconds
  memory_size                    = var.ingest_lambda.memory_mb
  reserved_concurrent_executions = var.reserved_concurrent_executions

  environment {
    variables = {
      LOG_LEVEL                        = var.log_level
      OPENSEARCH_HOST                  = var.opensearch_host != "" ? var.opensearch_host : local.opensearch_endpoint
      OPENSEARCH_CREDENTIALS_SECRET_ID = var.deploy_stac_server_opensearch_serverless ? "" : aws_secretsmanager_secret.opensearch_stac_user_password_secret.arn
      COLLECTION_TO_INDEX_MAPPINGS     = var.collection_to_index_mappings
      POST_INGEST_TOPIC_ARN            = aws_sns_topic.stac_server_post_ingest_sns_topic.arn
      STAC_API_URL                     = var.stac_api_url
      CORS_ORIGIN                      = var.cors_origin
      CORS_CREDENTIALS                 = var.cors_credentials
      CORS_METHODS                     = var.cors_methods
      CORS_HEADERS                     = var.cors_headers
      ENABLE_INGEST_ACTION_TRUNCATE    = var.enable_ingest_action_truncate
    }
  }

  dynamic "vpc_config" {
    for_each = { for i, j in [var.deploy_stac_server_outside_vpc] : i => j if var.deploy_stac_server_outside_vpc != true }

    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }
}

resource "aws_sns_topic" "stac_server_ingest_sns_topic" {
  name = "${local.name_prefix}-stac-server-ingest"
}

resource "aws_sns_topic" "stac_server_post_ingest_sns_topic" {
  name = "${local.name_prefix}-stac-server-post-ingest"
}

resource "aws_sns_topic_subscription" "stac_server_ingest_sqs_subscription" {
  count     = length(concat([aws_sns_topic.stac_server_ingest_sns_topic.arn], var.ingest_sns_topic_arns))
  topic_arn = element(concat([aws_sns_topic.stac_server_ingest_sns_topic.arn], var.ingest_sns_topic_arns), count.index)
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.stac_server_ingest_sqs_queue.arn
}

resource "aws_sqs_queue" "stac_server_ingest_sqs_queue" {
  name_prefix                = "${local.name_prefix}-stac-server-queue"
  visibility_timeout_seconds = var.ingest_sqs_timeout
  receive_wait_time_seconds  = var.ingest_sqs_receive_wait_time_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.stac_server_ingest_dead_letter_sqs_queue.arn
    maxReceiveCount     = var.ingest_sqs_max_receive_count
  })
}

resource "aws_sqs_queue" "stac_server_ingest_dead_letter_sqs_queue" {
  name_prefix                = "${local.name_prefix}-stac-server-dlq"
  visibility_timeout_seconds = var.ingest_sqs_dlq_timeout
}

resource "aws_sqs_queue_policy" "stac_server_ingest_sqs_queue_policy" {
  queue_url = aws_sqs_queue.stac_server_ingest_sqs_queue.id
  policy    = data.aws_iam_policy_document.stac_server_ingest_sqs_policy.json
}

data "aws_iam_policy_document" "stac_server_ingest_sqs_policy" {

  # SNS + non-roles
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.stac_server_ingest_sqs_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = local.non_role_arns
    }
  }

  # handle roles - both directly used or assumed by STS
  dynamic "statement" {
    for_each = length(local.role_arns) > 0 ? [1] : []
    content {
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = local.role_arns
      }

      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.stac_server_ingest_sqs_queue.arn]
    }
  }
}

resource "aws_lambda_event_source_mapping" "stac_server_ingest_sqs_lambda_event_source_mapping" {
  event_source_arn = aws_sqs_queue.stac_server_ingest_sqs_queue.arn
  function_name    = aws_lambda_function.stac_server_ingest.function_name
}

resource "aws_lambda_permission" "stac_server_ingest_sqs_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stac_server_ingest.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.stac_server_ingest_sqs_queue.arn
}
