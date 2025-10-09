# Creates the feeder lambda
module "lambda" {
  source = "./lambda"

  function_name          = local.name_main
  lambda_config          = var.feeder_config.lambda
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  warning_sns_topic_arn  = var.warning_sns_topic_arn
  critical_sns_topic_arn = var.critical_sns_topic_arn
  lambda_env_vars        = var.builtin_feeder_definitions_variables
}

# Allow this feeder lambda to read from and delete messages in the feeder SQS queue. Also allow it to send
# messages to the process queue
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

  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage",
    ]

    # TODO: Change this to the process queue ARN once we have it as a variable
    resources = [
      "arn:aws:sqs:us-west-2:662634391897:fd-jai-feed-tes-cirrus-process",
    ]
  }
}

resource "aws_iam_role_policy" "general_perms" {
  name   = "${local.name_main}-generalperms"
  role   = module.lambda.role_name
  policy = data.aws_iam_policy_document.feeder_lambda_general_perms.json
}

# Feeder queue perms to invoke this lambda; required for sqs -> lambda triggers
resource "aws_lambda_permission" "sqs_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.feeder_queue.arn
}

# Feeder queue -> lambda event source mapping
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.feeder_queue.arn
  function_name    = module.lambda.function_name

  depends_on = [
    aws_lambda_permission.sqs_lambda_permission
  ]

  # TODO:
  # This is the key setting that enables partial batch failure reporting.
  # The Lambda must return a specific JSON structure for this to work, so whether to enable this is up for discussion
  # function_response_types = ["ReportBatchItemFailures"]
}
