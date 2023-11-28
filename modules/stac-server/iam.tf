resource "aws_iam_role" "stac_api_lambda_role" {
  name_prefix = "${local.name_prefix}-stac-server-${data.aws_region.current.name}"

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

locals {
  stac_api_lambda_policy_stmts = [for x in
    [{
      Action = [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
      ]
      Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.name_prefix}-stac-server*:*"
      Effect   = "Allow"
      },
      {
        Action   = ["logs:PutLogEvents"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.name_prefix}-stac-server-*:*:*"
        Effect   = "Allow"
      },
      {
        Action   = ["es:*"]
        Resource = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/*"
        Effect   = "Allow"
      },
      {
        Action = [
          "sqs:GetQueueUrl",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
        ],
        Resource = aws_sqs_queue.stac_server_ingest_sqs_queue.arn
        Effect   = "Allow"
      },
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ],
        Resource = aws_sqs_queue.stac_server_ingest_sqs_queue.arn
        Effect   = "Allow"
      },
      {
        Action   = ["lambda:InvokeFunction"]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action   = ["kms:*"]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action   = ["aoss:*"]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action   = ["secretsmanager:*"]
        Resource = "*"
        Effect   = "Allow"
      },
      length(var.stac_server_s3_bucket_arns) == 0 ? null :
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = var.stac_server_s3_bucket_arns
      }
  ] : x if x != null]
}

resource "aws_iam_policy" "stac_api_lambda_policy" {
  name_prefix = "${local.name_prefix}-stac-server-${data.aws_region.current.name}"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.stac_api_lambda_policy_stmts
  })
}

resource "aws_iam_role_policy_attachment" "stac_api_lambda_vpc_policy_attachment" {
  role       = aws_iam_role.stac_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "stac_api_lambda_base_policy" {
  role       = aws_iam_role.stac_api_lambda_role.name
  policy_arn = aws_iam_policy.stac_api_lambda_policy.arn
}

resource "aws_iam_role" "stac_api_gw_role" {
  name_prefix = "${local.name_prefix}-stac-server-${data.aws_region.current.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "stac_api_gw_policy" {
  name_prefix = "${local.name_prefix}-stac-server-${data.aws_region.current.name}-apigw"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:DescribeLogGroups",
              "logs:DescribeLogStreams",
              "logs:PutLogEvents",
              "logs:GetLogEvents",
              "logs:FilterLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "stac_api_gw_base_policy" {
  role       = aws_iam_role.stac_api_gw_role.name
  policy_arn = aws_iam_policy.stac_api_gw_policy.arn
}
