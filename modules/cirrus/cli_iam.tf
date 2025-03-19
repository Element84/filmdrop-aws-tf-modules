locals {
  create_cli_role = var.cirrus_cli_iam_role_trust_principal != null
}

resource "aws_iam_role" "cirrus_instance_cli_management_role" {
  count = local.create_cli_role ? 1 : 0

  name_prefix = "${var.resource_prefix}-cli-role-"
  description = "Role for cirrus cli management tool to assume"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow"
        Principal = {
          AWS = var.cirrus_cli_iam_role_trust_principal
        },
      }
    ]
  })
}

data "aws_iam_policy_document" "cirrus_instance_cli_management_policy" {
  count = local.create_cli_role ? 1 : 0

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${module.base.cirrus_payload_bucket}/*",
      "arn:aws:s3:::${module.base.cirrus_payload_bucket}"
    ]
  }

  statement {
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem"
    ]

    resources = [
      module.base.cirrus_state_dynamodb_table_arn,
      "${module.base.cirrus_state_dynamodb_table_arn}/index/*"
    ]
  }

  statement {
    actions = [
      "sqs:SendMessage"
    ]
    resources = [
      module.base.cirrus_process_sqs_queue_arn
    ]
  }
  statement {
    actions = [
      "lambda:InvokeFunction",
      "lambda:ListFunctions"
    ]
    resources = [
      "arn:aws:lambda:${local.current_region}:${local.current_account}:function:${var.resource_prefix}-*"
    ]
  }

  statement {
    actions = [
      "states:DescribeExecution"
    ]
    resources = [
      "arn:aws:states:${local.current_region}:${local.current_account}:stateMachine:${var.resource_prefix}-*"
    ]
  }
}

resource "aws_iam_role_policy" "cirrus_instance_cli_management_role_policy" {
  count = local.create_cli_role ? 1 : 0

  role   = aws_iam_role.cirrus_instance_cli_management_role[0].name
  policy = data.aws_iam_policy_document.cirrus_instance_cli_management_policy[0].json
}
