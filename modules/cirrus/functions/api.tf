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

resource "aws_api_gateway_rest_api" "cirrus_api_gateway" {
  name = "${var.cirrus_prefix}-api"

  endpoint_configuration {
    types = [var.api_rest_type]
  }

  lifecycle {
    ignore_changes = [policy]
  }

}

resource "aws_api_gateway_method" "cirrus_api_gateway_root_method" {
  rest_api_id   = aws_api_gateway_rest_api.cirrus_api_gateway.id
  resource_id   = aws_api_gateway_rest_api.cirrus_api_gateway.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cirrus_api_gateway_root_method_integration" {
  rest_api_id             = aws_api_gateway_rest_api.cirrus_api_gateway.id
  resource_id             = aws_api_gateway_rest_api.cirrus_api_gateway.root_resource_id
  http_method             = aws_api_gateway_method.cirrus_api_gateway_root_method.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.cirrus_api.arn}/invocations"
  integration_http_method = "GET"
}

resource "aws_api_gateway_resource" "cirrus_api_gateway_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.cirrus_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.cirrus_api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "cirrus_api_gateway_proxy_resource_method" {
  rest_api_id   = aws_api_gateway_rest_api.cirrus_api_gateway.id
  resource_id   = aws_api_gateway_resource.cirrus_api_gateway_proxy_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cirrus_root_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cirrus_api_gateway.id
  resource_id = aws_api_gateway_rest_api.cirrus_api_gateway.root_resource_id
  http_method = aws_api_gateway_method.cirrus_api_gateway_root_method.http_method
  type        = "AWS_PROXY"
}

resource "aws_api_gateway_integration" "cirrus_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cirrus_api_gateway.id
  resource_id = aws_api_gateway_resource.cirrus_api_gateway_proxy_resource.id
  http_method = aws_api_gateway_method.cirrus_api_gateway_proxy_resource_method.http_method
  type        = "AWS_PROXY"
}

resource "aws_api_gateway_integration" "cirrus_api_gateway_proxy_resource_method_integration" {
  rest_api_id             = aws_api_gateway_rest_api.cirrus_api_gateway.id
  resource_id             = aws_api_gateway_resource.cirrus_api_gateway_proxy_resource.id
  http_method             = aws_api_gateway_method.cirrus_api_gateway_proxy_resource_method.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.cirrus_api.arn}/invocations"
  integration_http_method = "GET"
}

resource "aws_api_gateway_deployment" "cirrus_api_gateway" {
  depends_on = [
    aws_api_gateway_integration.cirrus_api_gateway_root_method_integration,
    aws_api_gateway_integration.cirrus_api_gateway_proxy_resource_method_integration,
  ]

  rest_api_id       = aws_api_gateway_rest_api.cirrus_api_gateway.id
  stage_name        = var.cirrus_api_stage
  stage_description = var.cirrus_api_stage_description

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "cirrus_api_gateway_logs_group" {
  name = "/aws/apigateway/${var.cirrus_prefix}-api-${aws_api_gateway_deployment.cirrus_api_gateway.rest_api_id}/${aws_api_gateway_deployment.cirrus_api_gateway.stage_name}"
}

locals {
  access_log_format = "{\"requestId\":\"\\$context.requestId\",\"ip\":\"\\$context.identity.sourceIp\",\"caller\":\"\\$context.identity.caller\",\"user\":\"\\$context.identity.user\",\"requestTime\":\"\\$context.requestTime\",\"httpMethod\":\"\\$context.httpMethod\",\"resourcePath\":\"\\$context.resourcePath\",\"status\":\"\\$context.status\",\"protocol\":\"\\$context.protocol\",\"responseLength\":\"\\$context.responseLength\"}"
}

resource "null_resource" "enable_access_logs" {
  triggers = {
    stage_name              = aws_api_gateway_deployment.cirrus_api_gateway.stage_name
    rest_api_id             = aws_api_gateway_deployment.cirrus_api_gateway.rest_api_id
    apigw_access_logs_group = aws_cloudwatch_log_group.cirrus_api_gateway_logs_group.arn
    access_log_format       = local.access_log_format
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Update Access Logging on FilmDrop Cirrus API."
aws apigateway update-stage --rest-api-id ${aws_api_gateway_deployment.cirrus_api_gateway.rest_api_id} --stage-name ${aws_api_gateway_deployment.cirrus_api_gateway.stage_name} --patch-operations "[{\"op\": \"replace\",\"path\": \"/accessLogSettings/destinationArn\",\"value\": \"${aws_cloudwatch_log_group.cirrus_api_gateway_logs_group.arn}\"},{\"op\": \"replace\",\"path\": \"/accessLogSettings/format\",\"value\": \"${local.access_log_format}\"}]"

EOF
  }

  depends_on = [
    aws_api_gateway_account.cirrus_api_gateway_cw_role
  ]
}

resource "aws_lambda_permission" "cirrus_api_gateway_lambda_permission_root_resource" {
  statement_id  = "AllowExecutionFromAPIGatewayRootResource"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cirrus_api.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.cirrus_api_gateway.id}/*/*"
}

resource "aws_lambda_permission" "cirrus_api_gateway_lambda_permission_proxy_resource" {
  statement_id  = "AllowExecutionFromAPIGatewayProxyResource"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cirrus_api.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.cirrus_api_gateway.id}/*/*${aws_api_gateway_resource.cirrus_api_gateway_proxy_resource.path}"
}

resource "aws_api_gateway_account" "cirrus_api_gateway_cw_role" {
  cloudwatch_role_arn = aws_iam_role.cirrus_api_gw_role.arn
}

resource "aws_iam_role" "cirrus_api_gw_role" {
  name_prefix = "${var.cirrus_prefix}-cirrus-${data.aws_region.current.name}"

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

resource "aws_iam_policy" "cirrus_api_gw_policy" {
  name_prefix = "${var.cirrus_prefix}-cirrus-${data.aws_region.current.name}-apigw"

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

resource "aws_iam_role_policy_attachment" "cirrus_api_gw_base_policy" {
  role       = aws_iam_role.cirrus_api_gw_role.name
  policy_arn = aws_iam_policy.cirrus_api_gw_policy.arn
}
