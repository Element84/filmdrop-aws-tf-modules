# Creates the feeder lambda
module "lambda" {
  source = "./lambda"

  function_name          = local.name_main
  lambda_config          = var.feeder_config.lambda_new
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  warning_sns_topic_arn  = var.warning_sns_topic_arn
  critical_sns_topic_arn = var.critical_sns_topic_arn
}

# Add SQS perms the feeder lambda needs to read from the feeder queue
data "aws_iam_policy_document" "feeder_lambda_general_perms" {
  statement {
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
  role   = module.lambda.role_name
  policy = data.aws_iam_policy_document.feeder_lambda_general_perms.json
}

# Feeder queue perms to invoke the lambda
resource "aws_lambda_permission" "sqs_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.feeder_queue.arn
}

# Feeder queue event source mapping
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.feeder_queue.arn
  function_name    = module.lambda.function_name

  depends_on = [
    aws_lambda_permission.sqs_lambda_permission
  ]

  # TODO:
  # This is the key setting that enables partial batch failure reporting.
  # The Lambda must return a specific JSON structure for this to work.
  # function_response_types = ["ReportBatchItemFailures"]
}
