resource "aws_lambda_function" "stac_server_ingest" {
  filename         = "${path.module}/lambda/ingest/ingest.zip"
  function_name    = "stac-server-${var.stac_api_stage}-ingest"
  description      = "stac-server Ingest Lambda"
  role             = aws_iam_role.stac_api_lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/ingest/ingest.zip")
  runtime          = "nodejs16.x"
  timeout          = var.ingest_lambda_timeout
  memory_size      = var.ingest_lambda_memory
  reserved_concurrent_executions = var.reserved_concurrent_executions 

  environment {
    variables = {
        LOG_LEVEL                         = var.log_level
        OPENSEARCH_HOST                   = var.opensearch_host != "" ? var.opensearch_host : aws_opensearch_domain.stac_server_opensearch_domain.endpoint
        OPENSEARCH_CREDENTIALS_SECRET_ID	= aws_secretsmanager_secret.opensearch_stac_user_password_secret.arn
        COLLECTION_TO_INDEX_MAPPINGS      = var.collection_to_index_mappings
    }
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }
}

resource "aws_sns_topic" "stac_server_ingest_sns_topic" {
  name = "stac-server-${var.stac_api_stage}-ingest"
}

resource "aws_sns_topic_subscription" "stac_server_ingest_sqs_subscription" {
  count                = length(concat([aws_sns_topic.stac_server_ingest_sns_topic.arn], var.ingest_sns_topic_arns))
  topic_arn            = element(concat([aws_sns_topic.stac_server_ingest_sns_topic.arn], var.ingest_sns_topic_arns), count.index)
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.stac_server_ingest_sqs_queue.arn
}

resource "aws_sqs_queue" "stac_server_ingest_sqs_queue" {
  name_prefix                 = "stac-server-${var.stac_api_stage}-queue"
  visibility_timeout_seconds  = var.ingest_sqs_timeout
  receive_wait_time_seconds   = var.ingest_sqs_receive_wait_time_seconds
  policy                      = data.aws_iam_policy_document.stac_server_ingest_sqs_policy.json

  redrive_policy= jsonencode({
    deadLetterTargetArn = aws_sqs_queue.stac_server_ingest_dead_letter_sqs_queue.arn
    maxReceiveCount     = var.ingest_sqs_max_receive_count
  })
}

resource "aws_sqs_queue" "stac_server_ingest_dead_letter_sqs_queue" {
  name_prefix                 = "stac-server-${var.stac_api_stage}-dead-letter-queue"
  visibility_timeout_seconds  = var.ingest_sqs_dlq_timeout
}

data "aws_iam_policy_document" "stac_server_ingest_sqs_policy" {
  policy_id = "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stac-server-${var.stac_api_stage}-queue/SQSDefaultPolicy"

  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stac-server-${var.stac_api_stage}-queue",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = concat([aws_sns_topic.stac_server_ingest_sns_topic.arn], var.ingest_sns_topic_arns)
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

resource "null_resource" "stac_server_ingest_create_indices" {
  triggers = {
    stac_server_ingest = aws_lambda_function.stac_server_ingest.function_name
    opensearch_host    = var.opensearch_host != "" ? var.opensearch_host : aws_opensearch_domain.stac_server_opensearch_domain.endpoint
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Creating indices on Stac Server OpenSearch Service."
aws lambda invoke --function-name ${aws_lambda_function.stac_server_ingest.function_name} --cli-binary-format raw-in-base64-out --payload '{ "create_indices": true }' output

EOF

  }

  depends_on = [
    aws_lambda_function.stac_server_ingest,
    null_resource.invoke_stac_server_opensearch_user_initializer
  ]
}
