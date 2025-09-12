# LAMBDA IAM ROLE -- BASIC SETUP
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "cirrus_post_batch_lambda_assume_role" {

  statement {
    sid     = "LambdaServiceAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    # Conditions to prevent the "confused deputy" security problem
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:lambda:${local.current_region}:${local.current_account}:function:${var.resource_prefix}-post-batch"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

resource "aws_iam_role" "cirrus_post_batch_lambda" {
  name_prefix        = "${var.resource_prefix}-post-batch-"
  description        = "Lambda execution role for Cirrus builtin Task 'post-batch'"
  assume_role_policy = data.aws_iam_policy_document.cirrus_post_batch_lambda_assume_role.json
}
# ==============================================================================


# LAMBDA IAM ROLE -- MANAGED POLICY ATTACHMENTS
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cirrus_post_batch_lambda_vpc_access" {
  role       = aws_iam_role.cirrus_post_batch_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
# ==============================================================================


# LAMBDA IAM ROLE -- MAIN POLICY
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "cirrus_post_batch_lambda_role_main" {

  statement {
    sid    = "AllowS3BucketAndObjectRead"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCirrusSecretsManagerRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${local.current_region}:${local.current_account}:secret:${var.resource_prefix}-*"
    ]
  }

  statement {
    sid    = "AllowCirrusPayloadS3BucketWrite"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.cirrus_payload_bucket}/*"
    ]
  }

  statement {
    sid    = "AllowBatchLogGroupRead"
    effect = "Allow"
    actions = [
      "logs:GetLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.current_region}:${local.current_account}:log-group:/aws/batch/*"
    ]
  }
}

resource "aws_iam_role_policy" "cirrus_post_batch_lambda_role_main" {
  name_prefix = "${var.resource_prefix}-post-batch-policy-"
  role        = aws_iam_role.cirrus_post_batch_lambda.name
  policy      = data.aws_iam_policy_document.cirrus_post_batch_lambda_role_main.json
}
# ==============================================================================


# LAMBDA FUNCTION
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "cirrus_post_batch" {
  function_name    = "${var.resource_prefix}-post-batch"
  description      = "Lambda function for Cirrus builtin Task 'post-batch'"
  role             = aws_iam_role.cirrus_post_batch_lambda.arn
  architectures    = ["arm64"]
  runtime          = "python3.12"
  filename         = local.cirrus_lambda_filename
  source_code_hash = local.cirrus_lambda_zip_hash
  handler          = "post_batch.lambda_handler"
  timeout          = var.cirrus_post_batch_lambda_timeout
  memory_size      = var.cirrus_post_batch_lambda_memory
  publish          = true

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

  # Dependent on all IAM policies being created/attached to the role first
  depends_on = [
    aws_iam_role_policy_attachment.cirrus_post_batch_lambda_vpc_access,
    aws_iam_role_policy.cirrus_post_batch_lambda_role_main,
    null_resource.get_cirrus_lambda
  ]
}
# ==============================================================================


# LAMBDA CLOUDWATCH ALARMS
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cirrus_post_batch_lambda_errors_warning_alarm" {
  count = var.deploy_alarms ? 1 : 0

  alarm_name                = "WARNING: ${var.resource_prefix}-post-batch Lambda Errors Warning Alarm"
  alarm_description         = "${var.resource_prefix}-post-batch Lambda Errors Warning Alarm"
  statistic                 = "Sum"
  metric_name               = "Errors"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 10
  period                    = 60
  evaluation_periods        = 5
  namespace                 = "AWS/Lambda"
  treat_missing_data        = "notBreaching"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_post_batch.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_post_batch_lambda_errors_critical_alarm" {
  count = var.deploy_alarms ? 1 : 0

  alarm_name                = "CRITICAL: ${var.resource_prefix}-post-batch Lambda Errors Critical Alarm"
  alarm_description         = "${var.resource_prefix}-post-batch Lambda Errors Critical Alarm"
  statistic                 = "Sum"
  metric_name               = "Errors"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 100
  period                    = 60
  evaluation_periods        = 5
  namespace                 = "AWS/Lambda"
  treat_missing_data        = "notBreaching"
  alarm_actions             = [var.critical_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_post_batch.function_name
  }
}
# ==============================================================================
