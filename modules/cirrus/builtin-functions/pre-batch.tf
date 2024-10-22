resource "aws_iam_role" "cirrus_pre_batch_lambda_role" {
  name_prefix = "${var.cirrus_prefix}-process-role-"

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

resource "aws_iam_policy" "cirrus_pre_batch_lambda_policy" {
  name_prefix = "${var.cirrus_prefix}-process-policy-"

  # TODO: the secret thing is probably not gonna work without some fixes in boto3utils...
  # We should probably reconsider if this is the right solution.
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetBucketLocation"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": "secretsmanager:GetSecretValue",
      "Resource": [
        "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.cirrus_prefix}*"
      ],
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${var.cirrus_payload_bucket}*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cirrus_pre_batch_lambda_role_policy_attachment1" {
  role       = aws_iam_role.cirrus_pre_batch_lambda_role.name
  policy_arn = aws_iam_policy.cirrus_pre_batch_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "cirrus_pre_batch_lambda_role_policy_attachment2" {
  role       = aws_iam_role.cirrus_pre_batch_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "cirrus_pre_batch" {
  filename         = "${path.module}/cirrus-lambda-dist.zip"
  function_name    = "${var.cirrus_prefix}-pre-batch"
  description      = "Cirrus Pre-batch Lambda"
  role             = aws_iam_role.cirrus_pre_batch_lambda_role.arn
  handler          = "pre_batch.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/cirrus-lambda-dist.zip")
  runtime          = "python3.12"
  timeout          = var.cirrus_pre_batch_lambda_timeout
  memory_size      = var.cirrus_pre_batch_lambda_memory
  publish          = true
  architectures    = ["arm64"]

  environment {
    variables = {
      CIRRUS_LOG_LEVEL      = var.cirrus_log_level
      CIRRUS_PAYLOAD_BUCKET = var.cirrus_payload_bucket
    }
  }

  vpc_config {
    security_group_ids = var.vpc_security_group_ids
    subnet_ids         = var.vpc_subnet_ids
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_pre_batch_lambda_errors_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.cirrus_prefix}-pre-batch Lambda Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 10
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.cirrus_prefix}-pre-batch Cirrus Update-State Lambda Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_pre_batch.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_pre_batch_lambda_errors_critical_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "CRITICAL: ${var.cirrus_prefix}-pre-batch Lambda Errors Critical Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 100
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.cirrus_prefix}-pre-batch Cirrus Update-State Lambda Errors Critical Alarm"
  alarm_actions             = [var.critical_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_pre_batch.function_name
  }
}
