# FEEDER LAMBDA IAM ROLE -- BASIC SETUP
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "feeder_lambda_assume_role" {
  statement {
    sid     = "LambdaServiceAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    # Help prevent cross-account confused deputy
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

data "aws_iam_policy_document" "feeder_lambda_general_perms" {
  statement {
    sid    = "AllowSQSRead"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [
      aws_sqs_queue.feeder_queue.arn,
    ]
  }
}

resource "aws_iam_role_policy" "general_perms" {
  name   = "${local.name_main}-generalperms"
  role   = aws_iam_role.feeder_lambda.name
  policy = data.aws_iam_policy_document.feeder_lambda_general_perms.json
}

resource "aws_iam_role" "feeder_lambda" {
  name               = local.name_main
  description        = "Lambda execution role for Cirrus Feeder '${var.feeder_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.feeder_lambda_assume_role.json
}
# ==============================================================================

# FEEDER LAMBDA IAM ROLE -- MANAGED POLICY ATTACHMENTS
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.feeder_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_read_only" {
  role       = aws_iam_role.feeder_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.feeder_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
# ==============================================================================

# FEEDER LAMBDA SQS
# ------------------------------------------------------------------------------
resource "aws_lambda_permission" "sqs_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.feeder.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.feeder_queue.arn
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.feeder_queue.arn
  function_name    = aws_lambda_function.feeder.function_name

  depends_on = [
    aws_lambda_permission.sqs_lambda_permission
  ]

  # TODO:
  # This is the key setting that enables partial batch failure reporting.
  # The Lambda must return a specific JSON structure for this to work.
  # function_response_types = ["ReportBatchItemFailures"]
}
# ==============================================================================

# FEEDER LAMBDA FUNCTION -- REMOTE ZIP, LOCAL ZIP, OR IMAGE BASED
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "feeder" {
  function_name = local.name_main

  role         = aws_iam_role.feeder_lambda.arn
  package_type = "Zip"
  handler      = var.feeder_config.lambda.handler
  runtime      = var.feeder_config.lambda.runtime

  # Local ZIP handling.
  # Path is expected to be relative to the ROOT module of this deployment.
  filename = (
    var.feeder_config.lambda.filename != null
    ? "${path.root}/${var.feeder_config.lambda.filename}"
    : null
  )

  # Dependent on all IAM policies being created/attached to the role first
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_read_only,
    aws_iam_role_policy_attachment.lambda_vpc_access
  ]
}
# ==============================================================================
