locals {
  titiler_policy_stmts = [for x in [
    length(var.titiler_s3_bucket_arns) == 0 ? null : {
      Action   = ["s3:GetObject"]
      Effect   = "Allow"
      Resource = var.titiler_s3_bucket_arns
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

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  inline_policy {
    name = "titiler-mosaic-lambda-inline-policy"

    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = local.titiler_policy_stmts
    })
  }
}
