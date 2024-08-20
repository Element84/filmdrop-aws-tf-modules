resource "aws_iam_role" "cirrus_post_batch_lambda_role" {
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

resource "aws_iam_policy" "cirrus_post_batch_lambda_policy" {
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:GetLogEvents"
      ],
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/batch/*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cirrus_post_batch_lambda_role_policy_attachment1" {
  role       = aws_iam_role.cirrus_post_batch_lambda_role.name
  policy_arn = aws_iam_policy.cirrus_post_batch_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "cirrus_post_batch_lambda_role_policy_attachment2" {
  role       = aws_iam_role.cirrus_post_batch_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "cirrus_post_batch" {
  filename         = "${path.module}/cirrus-lambda-dist.zip"
  function_name    = "${var.cirrus_prefix}-post-batch"
  description      = "Cirrus Post-batch Lambda"
  role             = aws_iam_role.cirrus_post_batch_lambda_role.arn
  handler          = "post_batch.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/cirrus-lambda-dist.zip")
  runtime          = "python3.12"
  timeout          = var.cirrus_post_batch_lambda_timeout
  memory_size      = var.cirrus_post_batch_lambda_memory
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
