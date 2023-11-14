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

  environment {
    variables = {
        STAC_ID                         = var.stac_id
        STAC_TITLE                      = var.stac_title
        STAC_DESCRIPTION                = var.stac_description
        STAC_VERSION                    = var.stac_version
        LOG_LEVEL                       = var.log_level
        INGEST_BATCH_SIZE               = var.opensearch_batch_size
        STAC_DOCS_URL                   = var.stac_docs_url
        OPENSEARCH_HOST                 = var.opensearch_host != "" ? var.opensearch_host : aws_elasticsearch_domain.stac_server_opensearch_domain.endpoint
        ENABLE_TRANSACTIONS_EXTENSION   = var.enable_transactions_extension
        STAC_API_ROOTPATH               = "/${var.stac_api_stage}"
        PRE_HOOK                        = var.stac_pre_hook_lambda
        PRE_HOOK_AUTH_TOKEN             = var.stac_pre_hook_lambda_token
        PRE_HOOK_AUTH_TOKEN_TXN         = var.stac_pre_hook_lambda_token_txn
        POST_HOOK                       = var.stac_post_hook_lambda
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
  topic_arn            = aws_sns_topic.stac_server_ingest_sns_topic.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.stac_server_ingest_sqs_queue.arn
}

resource "aws_sqs_queue" "stac_server_ingest_sqs_queue" {
  name                        = "stac-server-${var.stac_api_stage}-queue"
  visibility_timeout_seconds  = var.ingest_sqs_timeout
  receive_wait_time_seconds   = var.ingest_sqs_receive_wait_time_seconds

  redrive_policy= jsonencode({
    deadLetterTargetArn = aws_sqs_queue.stac_server_ingest_dead_letter_sqs_queue.arn
    maxReceiveCount     = var.ingest_sqs_max_receive_count
  })
}

resource "aws_sqs_queue" "stac_server_ingest_dead_letter_sqs_queue" {
  name                        = "stac-server-${var.stac_api_stage}-dead-letter-queue"
  visibility_timeout_seconds  = var.ingest_sqs_dlq_timeout
}

resource "aws_sqs_queue_policy" "stac_server_ingest_sns_sqs_policy" {
  queue_url = aws_sqs_queue.stac_server_ingest_sqs_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.stac_server_ingest_sqs_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.stac_server_ingest_sns_topic.arn}"
        }
      }
    }
  ]
}
POLICY
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
    opensearch_host    = var.opensearch_host != "" ? var.opensearch_host : aws_elasticsearch_domain.stac_server_opensearch_domain.endpoint
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Creating indices on Stac Server OpenSearch Service."
aws lambda invoke --function-name ${aws_lambda_function.stac_server_ingest.function_name} --cli-binary-format raw-in-base64-out --payload '{ "create_indices": true }' output

EOF

  }

  depends_on = [aws_lambda_function.stac_server_ingest]
}
