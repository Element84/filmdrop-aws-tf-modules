locals {
  titiler_policy_stmts = [for x in [
    length(var.authorized_s3_arns) == 0 ? null : {
      Action   = ["s3:GetObject"]
      Effect   = "Allow"
      Resource = var.authorized_s3_arns
    },
    {
      Action = [
        "dynamodb:Query",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:PutItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:CreateTable",
        "dynamodb:DescribeTable"
      ]
      Effect   = "Allow"
      Resource = aws_dynamodb_table.titiler-mosaic-dynamodb-table.arn
    },
    ] : x if x != null
  ]
}

resource "aws_iam_role" "titiler-mosaic-lambda-role" {
  name_prefix = "titiler-mosaic-lambdaRole"

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

resource "aws_iam_role_policy" "titiler-mosaic-lambda-inline-policy" {
  name = "titiler-mosaic-lambda-inline-policy"
  role = aws_iam_role.titiler-mosaic-lambda-role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.titiler_policy_stmts
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.titiler-mosaic-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.titiler-mosaic-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
