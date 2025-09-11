resource "aws_iam_role" "cirrus_update_state_lambda_role" {
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

resource "aws_iam_policy" "cirrus_update_state_lambda_policy" {
  name_prefix = "${var.resource_prefix}-process-policy-"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": [
        "${var.cirrus_state_dynamodb_table_arn}",
        "${var.cirrus_state_dynamodb_table_arn}/index/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "timestream:DescribeEndpoints"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "timestream:WriteRecords"
      ],
      "Resource": "${var.cirrus_state_event_timestreamwrite_table_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${var.cirrus_process_sqs_queue_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${var.cirrus_payload_bucket}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
        "${var.cirrus_publish_sns_topic_arn}",
        "${var.cirrus_workflow_event_sns_topic_arn}"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cirrus_update_state_lambda_role_policy_attachment1" {
  role       = aws_iam_role.cirrus_update_state_lambda_role.name
  policy_arn = aws_iam_policy.cirrus_update_state_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "cirrus_update_state_lambda_role_policy_attachment2" {
  role       = aws_iam_role.cirrus_update_state_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "cirrus_update_state" {
  filename         = local.cirrus_lambda_filename
  function_name    = "${var.resource_prefix}-update-state"
  description      = "Cirrus Update-State Lambda"
  role             = aws_iam_role.cirrus_update_state_lambda_role.arn
  handler          = "update_state.lambda_handler"
  source_code_hash = local.cirrus_lambda_zip_hash
  runtime          = "python3.12"
  timeout          = var.cirrus_update_state_lambda_timeout
  memory_size      = var.cirrus_update_state_lambda_memory
  publish          = true
  architectures    = ["arm64"]

  environment {
    variables = {
      CIRRUS_LOG_LEVEL                = var.cirrus_log_level
      CIRRUS_DATA_BUCKET              = var.cirrus_data_bucket
      CIRRUS_PAYLOAD_BUCKET           = var.cirrus_payload_bucket
      CIRRUS_STATE_DB                 = var.cirrus_state_dynamodb_table_name
      CIRRUS_EVENT_DB_AND_TABLE       = "${var.cirrus_state_event_timestreamwrite_database_name}|${var.cirrus_state_event_timestreamwrite_table_name}"
      CIRRUS_WORKFLOW_EVENT_TOPIC_ARN = var.cirrus_workflow_event_sns_topic_arn
      CIRRUS_PUBLISH_TOPIC_ARN        = var.cirrus_publish_sns_topic_arn
      CIRRUS_PROCESS_QUEUE_URL        = var.cirrus_process_sqs_queue_url
    }
  }

  vpc_config {
    security_group_ids = var.vpc_security_group_ids
    subnet_ids         = var.vpc_subnet_ids
  }

  depends_on = [
    null_resource.get_cirrus_lambda
  ]
}

resource "aws_cloudwatch_event_rule" "cirrus_update_state_rule" {
  name = "${var.resource_prefix}-update-state-sfn-events"

  event_pattern = <<EOF
{
  "detail-type": [
    "Step Functions Execution Status Change"
  ],
  "source": [
    "aws.states"
  ],
  "detail": {
    "stateMachineArn": [
      {
        "prefix": "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.resource_prefix}-"
      }
    ],
    "status": [
      "SUCCEEDED",
      "FAILED",
      "ABORTED",
      "TIMED_OUT"
    ]
  }
}
EOF

}

resource "aws_cloudwatch_event_target" "cirrus_update_state_target" {
  target_id = "${var.resource_prefix}-update-state-event-target"
  arn       = aws_lambda_function.cirrus_update_state.arn
  rule      = aws_cloudwatch_event_rule.cirrus_update_state_rule.name

  dead_letter_config {
    arn = var.cirrus_update_state_dead_letter_sqs_queue_arn
  }

  retry_policy {
    maximum_event_age_in_seconds = 1800
  }
}

resource "aws_lambda_permission" "cirrus_update_state_event_bridge_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cirrus_update_state.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cirrus_update_state_rule.arn
}

resource "aws_cloudwatch_metric_alarm" "cirrus_update_state_lambda_errors_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-update-state Lambda Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 10
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix}-update-state Cirrus Update-State Lambda Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_update_state.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_update_state_lambda_errors_critical_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "CRITICAL: ${var.resource_prefix}-update-state Lambda Errors Critical Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 100
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix}-update-state Cirrus Update-State Lambda Errors Critical Alarm"
  alarm_actions             = [var.critical_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_update_state.function_name
  }
}
