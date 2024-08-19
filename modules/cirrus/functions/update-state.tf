resource "aws_iam_role" "cirrus_update_state_lambda_role" {
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

resource "aws_iam_policy" "cirrus_update_state_lambda_policy" {
  name_prefix = "${var.cirrus_prefix}-process-policy-"

  # TODO: the secret thing is probably not gonna work without some fixes in boto3utils...
  # We should probably reconsider if this is the right solution.
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
        "${var.cirrus_state_dynamodb_table_arn}/index.*"
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
        "states:GetExecutionHistory"
      ],
      "Resource": "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.cirrus_prefix}-*"
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
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${var.cirrus_payload_bucket}*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "${var.cirrus_workflow_event_sns_topic_arn}"
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
  filename                       = "${path.module}/cirrus-lambda-dist.zip"
  function_name                  = "${var.cirrus_prefix}-update-state"
  description                    = "Cirrus Update-State Lambda"
  role                           = aws_iam_role.cirrus_update_state_lambda_role.arn
  handler                        = "update_state.lambda_handler"
  source_code_hash               = filebase64sha256("${path.module}/cirrus-lambda-dist.zip")
  runtime                        = "python3.12"
  timeout                        = var.cirrus_update_state_lambda_timeout
  memory_size                    = var.cirrus_update_state_lambda_memory
  publish                        = true
  architectures                  = ["arm64"]

  environment {
    variables = {
      CIRRUS_LOG_LEVEL                = var.cirrus_log_level
      CIRRUS_DATA_BUCKET              = var.cirrus_data_bucket
      CIRRUS_PAYLOAD_BUCKET           = var.cirrus_payload_bucket
      CIRRUS_STATE_DB                 = var.cirrus_state_dynamodb_table_name
      CIRRUS_EVENT_DB_AND_TABLE       = "${var.cirrus_state_event_timestreamwrite_database_name}|${var.cirrus_state_event_timestreamwrite_table_name}"
      CIRRUS_WORKFLOW_EVENT_TOPIC_ARN = var.cirrus_workflow_event_sns_topic_arn
      CIRRUS_PROCESS_QUEUE_URL        = var.cirrus_process_sqs_queue_url
    }
  }

  vpc_config {
    security_group_ids           = var.vpc_security_group_ids
    subnet_ids                   = var.vpc_subnet_ids
  }
}
