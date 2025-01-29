locals {
  name_prefix = "fd-${var.project_name}-${var.environment}"
}


resource "aws_iam_role" "shared_api_gw_logging_role" {
  name_prefix = "${local.name_prefix}-${data.aws_region.current.name}-apigw-"

  assume_role_policy = <<-JSON_POLICY_STRING
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
  JSON_POLICY_STRING
}

resource "aws_iam_policy" "shared_api_gw_logging_role" {
  name_prefix = "${local.name_prefix}-${data.aws_region.current.name}-apigw-log-policy-"

  policy = <<-JSON_POLICY_STRING
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
  JSON_POLICY_STRING
}

resource "aws_iam_role_policy_attachment" "shared_api_gw_logging_role" {
  role       = aws_iam_role.shared_api_gw_logging_role.name
  policy_arn = aws_iam_policy.shared_api_gw_logging_role.arn
}

resource "aws_api_gateway_account" "shared_api_gw_logging_role" {
  cloudwatch_role_arn = aws_iam_role.shared_api_gw_logging_role.arn
}
