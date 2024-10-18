resource "aws_lambda_function" "additional" {
  for_each = var.additional_lambdas

  function_name = "${var.cirrus_prefix}-${each.key}"
  description   = each.value.description
  image_uri     = each.value.ecr_image_uri == null ? null : each.value.ecr_image_uri
  s3_bucket     = each.value.s3_bucket == null ? null : each.value.s3_bucket
  s3_key        = each.value.s3_key == null ? null : each.value.s3_key
  role          = contains(keys(var.additional_lambda_roles), each.key) ? aws_iam_role.cirrus_custom_lambda_role[each.key].arn : aws_iam_role.cirrus_default_lambda_role.arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  timeout       = each.value.timeout_seconds
  memory_size   = each.value.memory_mb
  publish       = each.value.publish
  architectures = each.value.architectures

  environment {
    variables = {
      for k, v in each.value.env_vars : k => v
    }
  }

  dynamic "vpc_config" {
    for_each = { for i, j in [each.value.vpc_enabled] : i => j if each.value.vpc_enabled }

    content {
      security_group_ids = var.vpc_security_group_ids
      subnet_ids         = var.vpc_subnet_ids
    }
  }

  depends_on = [
    aws_iam_role.cirrus_default_lambda_role,
    aws_iam_role_policy.cirrus_custom_lambda_role_policy
  ]
}


data "aws_iam_policy_document" "default_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cirrus_default_lambda_role" {
  name_prefix        = "${var.cirrus_prefix}-default-role-"
  assume_role_policy = data.aws_iam_policy_document.default_assume_role.json
}

resource "aws_iam_role_policy_attachment" "default_basic_execution" {
  role       = aws_iam_role.cirrus_default_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "default_vpc_access" {
  role       = aws_iam_role.cirrus_default_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "default_read_only" {
  role       = aws_iam_role.cirrus_default_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

resource "aws_iam_role" "cirrus_custom_lambda_role" {
  for_each = var.additional_lambda_roles

  name_prefix        = "${var.cirrus_prefix}-${each.key}-role-"
  assume_role_policy = data.aws_iam_policy_document.default_assume_role.json
}

resource "aws_iam_role_policy" "cirrus_custom_lambda_role_policy" {
  for_each = var.additional_lambda_roles

  name_prefix = "${var.cirrus_prefix}-${each.key}-policy-"
  role        = aws_iam_role.cirrus_custom_lambda_role[each.key].id

  policy = each.value
}

resource "aws_cloudwatch_metric_alarm" "cirrus_additional_lambda_errors_warning_alarm" {
  for_each = var.additional_warning_alarms

  alarm_name                = "WARNING: ${var.cirrus_prefix}-${each.key} Lambda Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = each.value.evaluation_periods
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = each.value.period
  statistic                 = "Sum"
  threshold                 = each.value.threshold
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.cirrus_prefix}-${each.key} Cirrus Lambda Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.additional[each.key].arn
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_additional_lambda_errors_critical_alarm" {
  for_each = var.additional_error_alarms

  alarm_name                = "CRITICAL: ${var.cirrus_prefix}-${each.key} Lambda Errors Critical Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = each.value.evaluation_periods
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = each.value.period
  statistic                 = "Sum"
  threshold                 = each.value.threshold
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.cirrus_prefix}-${each.key} Cirrus Lambda Errors Critical Alarm"
  alarm_actions             = [var.critical_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.additional[each.key].arn
  }
}
