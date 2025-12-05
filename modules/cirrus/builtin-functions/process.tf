resource "aws_iam_role" "cirrus_process_lambda_role" {
  name_prefix = "${var.resource_prefix}-process-role-"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

data "aws_iam_policy_document" "cirrus_process_lambda_policy_main_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.resource_prefix}*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      var.cirrus_state_dynamodb_table_arn,
      "${var.cirrus_state_dynamodb_table_arn}/index/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage"
    ]
    resources = [
      var.cirrus_process_sqs_queue_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "states:StartExecution"
    ]
    resources = [
      "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.resource_prefix}-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.cirrus_payload_bucket}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      var.cirrus_workflow_event_sns_topic_arn
    ]
  }
}

data "aws_iam_policy_document" "cirrus_process_lambda_policy_timestream_doc" {
  count = var.workflow_metrics_timestream_enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "timestream:DescribeEndpoints"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "timestream:WriteRecords"
    ]
    resources = [
      var.cirrus_state_event_timestreamwrite_table_arn
    ]
  }
}

resource "aws_iam_policy" "cirrus_process_lambda_policy_main" {
  policy = data.aws_iam_policy_document.cirrus_process_lambda_policy_main_doc.json
}

resource "aws_iam_policy" "cirrus_process_lambda_policy_timestream" {
  count  = var.workflow_metrics_timestream_enabled ? 1 : 0
  policy = data.aws_iam_policy_document.cirrus_process_lambda_policy_timestream_doc[0].json
}

resource "aws_iam_role_policy_attachment" "cirrus_process_lambda_role_policy_attachment1" {
  role       = aws_iam_role.cirrus_process_lambda_role.name
  policy_arn = aws_iam_policy.cirrus_process_lambda_policy_main.arn
}

resource "aws_iam_role_policy_attachment" "cirrus_process_lambda_role_policy_attachment2" {
  role       = aws_iam_role.cirrus_process_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cirrus_process_lambda_role_policy_attachment3" {
  count      = var.workflow_metrics_cloudwatch_enabled ? 1 : 0
  role       = aws_iam_role.cirrus_process_lambda_role.name
  policy_arn = var.cirrus_workflow_metrics_write_policy_arn
}

resource "aws_iam_role_policy_attachment" "cirrus_process_lambda_role_policy_attachment4" {
  count      = var.workflow_metrics_timestream_enabled ? 1 : 0
  role       = aws_iam_role.cirrus_process_lambda_role.name
  policy_arn = aws_iam_policy.cirrus_process_lambda_policy_timestream[0].arn
}

resource "aws_lambda_function" "cirrus_process" {
  filename                       = local.cirrus_lambda_filename
  function_name                  = "${var.resource_prefix}-process"
  description                    = "Cirrus Process Lambda"
  role                           = aws_iam_role.cirrus_process_lambda_role.arn
  handler                        = "process.lambda_handler"
  source_code_hash               = local.cirrus_lambda_zip_hash
  runtime                        = "python${local.cirrus_lambda_pyversion}"
  timeout                        = var.cirrus_process_lambda_timeout
  memory_size                    = var.cirrus_process_lambda_memory
  reserved_concurrent_executions = var.cirrus_process_lambda_reserved_concurrency
  publish                        = true
  architectures                  = ["arm64"]

  environment {
    variables = merge(
      {
        CIRRUS_LOG_LEVEL                = var.cirrus_log_level
        CIRRUS_DATA_BUCKET              = var.cirrus_data_bucket
        CIRRUS_PAYLOAD_BUCKET           = var.cirrus_payload_bucket
        CIRRUS_STATE_DB                 = var.cirrus_state_dynamodb_table_name
        CIRRUS_WORKFLOW_EVENT_TOPIC_ARN = var.cirrus_workflow_event_sns_topic_arn
        CIRRUS_BASE_WORKFLOW_ARN        = "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.resource_prefix}-"
      },
      var.workflow_metrics_timestream_enabled ? {
        CIRRUS_EVENT_DB_AND_TABLE = "${var.cirrus_state_event_timestreamwrite_database_name}|${var.cirrus_state_event_timestreamwrite_table_name}"
      } : {},
      var.workflow_metrics_cloudwatch_enabled ? {
        CIRRUS_WORKFLOW_LOG_GROUP = var.cirrus_workflow_metrics_log_group_name
      } : {}
    )
  }

  vpc_config {
    security_group_ids = var.vpc_security_group_ids
    subnet_ids         = var.vpc_subnet_ids
  }

  depends_on = [
    null_resource.get_cirrus_lambda
  ]
}

resource "aws_lambda_event_source_mapping" "cirrus_process_sqs_lambda_event_source_mapping" {
  event_source_arn = var.cirrus_process_sqs_queue_arn
  function_name    = aws_lambda_function.cirrus_process.function_name
}

resource "aws_lambda_permission" "cirrus_process_sqs_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cirrus_process.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = var.cirrus_process_sqs_queue_arn
}

resource "aws_cloudwatch_metric_alarm" "cirrus_process_lambda_errors_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-process Lambda Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 10
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix}-process Cirrus Update-State Lambda Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_process.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_process_lambda_errors_critical_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "CRITICAL: ${var.resource_prefix}-process Lambda Errors Critical Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 100
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix}-process Cirrus Update-State Lambda Errors Critical Alarm"
  alarm_actions             = [var.critical_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_process.function_name
  }
}
