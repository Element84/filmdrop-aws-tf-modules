resource "aws_lambda_function" "stac_server_api" {
  filename         = "${path.module}/lambda/api/api.zip"
  function_name    = "${local.name_prefix}-stac-server-api"
  description      = "stac-server API Lambda"
  role             = aws_iam_role.stac_api_lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/api/api.zip")
  runtime          = "nodejs18.x"
  timeout          = var.api_lambda_timeout
  memory_size      = var.api_lambda_memory

  environment {
    variables = {
      STAC_ID                 = var.stac_id
      STAC_TITLE              = var.stac_title
      STAC_DESCRIPTION        = var.stac_description
      LOG_LEVEL               = var.log_level
      REQUEST_LOGGING_ENABLED = var.request_logging_enabled
      STAC_DOCS_URL           = var.stac_docs_url
      OPENSEARCH_HOST = (
        var.opensearch_host != ""
        ? var.opensearch_host
        : local.opensearch_endpoint
      )
      ENABLE_TRANSACTIONS_EXTENSION = var.enable_transactions_extension
      STAC_API_ROOTPATH = (
        var.stac_api_rootpath != null
        ? var.stac_api_rootpath
        : "/${var.stac_api_stage}"
      )
      PRE_HOOK = (
        var.stac_server_auth_pre_hook_enabled && var.stac_server_pre_hook_lambda_arn == ""
        ? one(aws_lambda_function.stac_server_api_auth_pre_hook[*].arn)
        : var.stac_server_pre_hook_lambda_arn
      )
      POST_HOOK                        = var.stac_server_post_hook_lambda_arn
      OPENSEARCH_CREDENTIALS_SECRET_ID = var.deploy_stac_opensearch_serverless ? "" : aws_secretsmanager_secret.opensearch_stac_user_password_secret.arn
      COLLECTION_TO_INDEX_MAPPINGS     = var.collection_to_index_mappings
    }
  }

  dynamic "vpc_config" {
    for_each = { for i, j in [var.deploy_stac_opensearch_serverless] : i => j if var.deploy_stac_opensearch_serverless != true }

    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }
}

resource "aws_api_gateway_rest_api" "stac_server_api_gateway" {
  name = "${local.name_prefix}-stac-server"

  endpoint_configuration {
    types = [var.api_rest_type]
  }

  lifecycle {
    ignore_changes = [policy]
  }

}

resource "aws_api_gateway_method" "stac_server_api_gateway_root_method" {
  rest_api_id   = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id   = aws_api_gateway_rest_api.stac_server_api_gateway.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "stac_server_api_gateway_root_method_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id             = aws_api_gateway_rest_api.stac_server_api_gateway.root_resource_id
  http_method             = aws_api_gateway_method.stac_server_api_gateway_root_method.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.stac_server_api.arn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_resource" "stac_server_api_gateway_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.stac_server_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.stac_server_api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "stac_server_api_gateway_proxy_resource_method" {
  rest_api_id   = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id   = aws_api_gateway_resource.stac_server_api_gateway_proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "stac_root_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id   = aws_api_gateway_rest_api.stac_server_api_gateway.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_method_response" "stac_root_options_200" {
  rest_api_id = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id = aws_api_gateway_rest_api.stac_server_api_gateway.root_resource_id
  http_method = aws_api_gateway_method.stac_root_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "stac_root_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id = aws_api_gateway_rest_api.stac_server_api_gateway.root_resource_id
  http_method = aws_api_gateway_method.stac_root_options_method.http_method
  type        = "MOCK"
}

resource "aws_api_gateway_integration_response" "stac_root_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id = aws_api_gateway_rest_api.stac_server_api_gateway.root_resource_id
  http_method = aws_api_gateway_method.stac_root_options_method.http_method
  status_code = aws_api_gateway_method_response.stac_root_options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "stac_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id   = aws_api_gateway_resource.stac_server_api_gateway_proxy_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_method_response" "stac_options_200" {
  rest_api_id = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id = aws_api_gateway_resource.stac_server_api_gateway_proxy_resource.id
  http_method = aws_api_gateway_method.stac_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "stac_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id = aws_api_gateway_resource.stac_server_api_gateway_proxy_resource.id
  http_method = aws_api_gateway_method.stac_options_method.http_method
  type        = "MOCK"
}

resource "aws_api_gateway_integration_response" "stac_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id = aws_api_gateway_resource.stac_server_api_gateway_proxy_resource.id
  http_method = aws_api_gateway_method.stac_options_method.http_method
  status_code = aws_api_gateway_method_response.stac_options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_integration" "stac_server_api_gateway_proxy_resource_method_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id             = aws_api_gateway_resource.stac_server_api_gateway_proxy_resource.id
  http_method             = aws_api_gateway_method.stac_server_api_gateway_proxy_resource_method.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.stac_server_api.arn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "stac_server_api_gateway" {
  depends_on = [
    aws_api_gateway_integration.stac_server_api_gateway_root_method_integration,
    aws_api_gateway_integration.stac_server_api_gateway_proxy_resource_method_integration,
  ]

  rest_api_id       = aws_api_gateway_rest_api.stac_server_api_gateway.id
  stage_name        = var.stac_api_stage
  stage_description = var.stac_api_stage_description

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "stac_server_api_gateway_logs_group" {
  name = "/aws/apigateway/${local.name_prefix}-stac-server-${aws_api_gateway_deployment.stac_server_api_gateway.rest_api_id}/${aws_api_gateway_deployment.stac_server_api_gateway.stage_name}"
}

locals {
  access_log_format = "{\"requestId\":\"\\$context.requestId\",\"ip\":\"\\$context.identity.sourceIp\",\"caller\":\"\\$context.identity.caller\",\"user\":\"\\$context.identity.user\",\"requestTime\":\"\\$context.requestTime\",\"httpMethod\":\"\\$context.httpMethod\",\"resourcePath\":\"\\$context.resourcePath\",\"status\":\"\\$context.status\",\"protocol\":\"\\$context.protocol\",\"responseLength\":\"\\$context.responseLength\"}"
}

resource "null_resource" "enable_access_logs" {
  triggers = {
    stage_name              = aws_api_gateway_deployment.stac_server_api_gateway.stage_name
    rest_api_id             = aws_api_gateway_deployment.stac_server_api_gateway.rest_api_id
    apigw_access_logs_group = aws_cloudwatch_log_group.stac_server_api_gateway_logs_group.arn
    access_log_format       = local.access_log_format
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Update Access Logging on FilmDrop Stac Server API."
aws apigateway update-stage --rest-api-id ${aws_api_gateway_deployment.stac_server_api_gateway.rest_api_id} --stage-name ${aws_api_gateway_deployment.stac_server_api_gateway.stage_name} --patch-operations "[{\"op\": \"replace\",\"path\": \"/accessLogSettings/destinationArn\",\"value\": \"${aws_cloudwatch_log_group.stac_server_api_gateway_logs_group.arn}\"},{\"op\": \"replace\",\"path\": \"/accessLogSettings/format\",\"value\": \"${local.access_log_format}\"}]"

EOF
  }

  depends_on = [
    aws_api_gateway_account.stac_server_api_gateway_cw_role
  ]
}

resource "aws_lambda_permission" "stac_server_api_gateway_lambda_permission_root_resource" {
  statement_id  = "AllowExecutionFromAPIGatewayRootResource"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stac_server_api.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.stac_server_api_gateway.id}/*/*"
}

resource "aws_lambda_permission" "stac_server_api_gateway_lambda_permission_proxy_resource" {
  statement_id  = "AllowExecutionFromAPIGatewayProxyResource"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stac_server_api.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.stac_server_api_gateway.id}/*/*${aws_api_gateway_resource.stac_server_api_gateway_proxy_resource.path}"
}

resource "aws_api_gateway_account" "stac_server_api_gateway_cw_role" {
  cloudwatch_role_arn = aws_iam_role.stac_api_gw_role.arn
}
