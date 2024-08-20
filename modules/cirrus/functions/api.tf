resource "aws_iam_role" "cirrus_api_lambda_role" {
  name_prefix = "${var.cirrus_prefix}-api-role-"

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

resource "aws_iam_policy" "cirrus_api_lambda_policy" {
  name_prefix = "${var.cirrus_prefix}-api-policy-"

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
      "Resource": "arn:aws:s3:::${var.cirrus_data_bucket}*",
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
        "timestream:Select"
      ],
      "Resource": "${var.cirrus_state_event_timestreamwrite_table_arn}"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cirrus_api_lambda_role_policy_attachment1" {
  role       = aws_iam_role.cirrus_api_lambda_role.name
  policy_arn = aws_iam_policy.cirrus_api_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "cirrus_api_lambda_role_policy_attachment2" {
  role       = aws_iam_role.cirrus_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "cirrus_api" {
  filename         = "${path.module}/cirrus-lambda-dist.zip"
  function_name    = "${var.cirrus_prefix}-api"
  description      = "Cirrus API Lambda"
  role             = aws_iam_role.cirrus_api_lambda_role.arn
  handler          = "api.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/cirrus-lambda-dist.zip")
  runtime          = "python3.12"
  timeout          = var.cirrus_api_lambda_timeout
  memory_size      = var.cirrus_api_lambda_memory
  publish          = true
  architectures    = ["arm64"]

  environment {
    variables = {
      CIRRUS_LOG_LEVEL          = var.cirrus_log_level
      CIRRUS_DATA_BUCKET        = var.cirrus_data_bucket
      CIRRUS_PAYLOAD_BUCKET     = var.cirrus_payload_bucket
      CIRRUS_STATE_DB           = var.cirrus_state_dynamodb_table_name
      CIRRUS_EVENT_DB_AND_TABLE = "${var.cirrus_state_event_timestreamwrite_database_name}|${var.cirrus_state_event_timestreamwrite_table_name}"
    }
  }

  vpc_config {
    security_group_ids = var.vpc_security_group_ids
    subnet_ids         = var.vpc_subnet_ids
  }
}
