locals {
  is_private_endpoint = var.api_rest_type == "PRIVATE" ? true : false
}


resource "aws_lambda_function" "stac_server_api" {
  filename         = local.resolved_api_lambda_zip_filepath
  function_name    = "${local.name_prefix}-stac-server-api"
  description      = "stac-server API Lambda"
  role             = aws_iam_role.stac_api_lambda_role.arn
  handler          = var.api_lambda.handler
  source_code_hash = filebase64sha256(local.resolved_api_lambda_zip_filepath)
  runtime          = var.api_lambda.runtime
  timeout          = var.api_lambda.timeout_seconds
  memory_size      = var.api_lambda.memory_mb

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
      ENABLE_COLLECTIONS_AUTHX      = var.enable_collections_authx
      ENABLE_FILTER_AUTHX           = var.enable_filter_authx
      ITEMS_MAX_LIMIT               = var.items_max_limit
      ENABLE_RESPONSE_COMPRESSION   = var.enable_response_compression
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
      OPENSEARCH_CREDENTIALS_SECRET_ID = var.deploy_stac_server_opensearch_serverless ? "" : aws_secretsmanager_secret.opensearch_stac_user_password_secret.arn
      COLLECTION_TO_INDEX_MAPPINGS     = var.collection_to_index_mappings
      STAC_API_URL                     = var.stac_api_url
      CORS_ORIGIN                      = var.cors_origin
      CORS_CREDENTIALS                 = var.cors_credentials
      CORS_METHODS                     = var.cors_methods
      CORS_HEADERS                     = var.cors_headers
    }
  }

  dynamic "vpc_config" {
    for_each = { for i, j in [var.deploy_stac_server_outside_vpc] : i => j if var.deploy_stac_server_outside_vpc != true }

    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }
}

resource "aws_security_group" "stac_server_api_gateway_private_vpce" {
  count = local.is_private_endpoint ? 1 : 0

  name_prefix = "${local.name_prefix}-apigw-vcpe-sg-"
  description = "Allows TCP inbound on 443 from VPC private subnet CIDRs"

  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "stac_server_api_gateway_private_vcpe" {
  for_each = local.is_private_endpoint ? { for s in data.aws_subnet.selected : s.id => s } : {}

  security_group_id = aws_security_group.stac_server_api_gateway_private_vpce[0].id
  description       = "Allow TCP on 443 for subnet ${each.value.id}"

  cidr_ipv4   = each.value.cidr_block
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_endpoint" "stac_server_api_gateway_private" {
  count = local.is_private_endpoint ? 1 : 0

  service_name        = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  vpc_id              = var.vpc_id
  vpc_endpoint_type   = "Interface"
  ip_address_type     = "ipv4"
  subnet_ids          = data.aws_subnet.selected[*].id
  auto_accept         = true
  private_dns_enabled = false
  security_group_ids = concat(
    aws_security_group.stac_server_api_gateway_private_vpce[*].id,
    coalesce(var.private_api_additional_security_group_ids, [])
  )

  dns_options {
    dns_record_ip_type = "ipv4"
  }
}

resource "aws_api_gateway_rest_api" "stac_server_api_gateway" {
  name = "${local.name_prefix}-stac-server"

  endpoint_configuration {
    types            = [var.api_rest_type]
    vpc_endpoint_ids = local.is_private_endpoint ? aws_vpc_endpoint.stac_server_api_gateway_private[*].id : null
  }
}

data "aws_iam_policy_document" "stac_server_api_gateway_private" {
  count = local.is_private_endpoint ? 1 : 0

  statement {
    sid       = "DenyApiInvokeForNonVpceTraffic"
    effect    = "Deny"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.stac_server_api_gateway.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      variable = "aws:SourceVpce"
      test     = "StringNotEquals"
      values   = [aws_vpc_endpoint.stac_server_api_gateway_private[0].id]
    }
  }

  statement {
    sid       = "AllowApiInvoke"
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.stac_server_api_gateway.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_api_gateway_rest_api_policy" "stac_server_api_gateway_private" {
  count = local.is_private_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.stac_server_api_gateway.id
  policy      = data.aws_iam_policy_document.stac_server_api_gateway_private[0].json
}

resource "aws_api_gateway_method" "stac_server_api_gateway_root_method" {
  rest_api_id   = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id   = aws_api_gateway_rest_api.stac_server_api_gateway.root_resource_id
  http_method   = "ANY"
  authorization = var.api_method_authorization_type
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
  authorization = var.api_method_authorization_type
}

resource "aws_api_gateway_method" "stac_root_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.stac_server_api_gateway.id
  resource_id   = aws_api_gateway_rest_api.stac_server_api_gateway.root_resource_id
  http_method   = "OPTIONS"
  authorization = var.api_method_authorization_type
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
  authorization = var.api_method_authorization_type
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

resource "aws_api_gateway_domain_name" "stac_server_api_gateway_domain_name" {
  count           = local.is_private_endpoint == true && var.domain_alias != "" && var.private_certificate_arn != "" ? 1 : 0
  certificate_arn = var.private_certificate_arn
  domain_name     = var.domain_alias

  endpoint_configuration {
    types = ["PRIVATE"]
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/domainnames/*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/domainnames/*",
      "Condition": {
        "StringNotEquals": {
          "aws:SourceVpce": "${aws_vpc_endpoint.stac_server_api_gateway_private[0].id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_api_gateway_domain_name_access_association" "titiler_api_gateway_domain_name_access_association" {
  count                          = local.is_private_endpoint == true && var.domain_alias != "" && var.private_certificate_arn != "" ? 1 : 0
  access_association_source      = aws_vpc_endpoint.stac_server_api_gateway_private[0].id
  access_association_source_type = "VPCE"
  domain_name_arn                = aws_api_gateway_domain_name.stac_server_api_gateway_domain_name[0].arn
}

resource "aws_api_gateway_base_path_mapping" "stac_server_api_gateway_domain_mapping" {
  count          = local.is_private_endpoint == true && var.domain_alias != "" && var.private_certificate_arn != "" ? 1 : 0
  domain_name    = aws_api_gateway_domain_name.stac_server_api_gateway_domain_name[0].domain_name
  domain_name_id = aws_api_gateway_domain_name.stac_server_api_gateway_domain_name[0].domain_name_id
  api_id         = aws_api_gateway_rest_api.stac_server_api_gateway.id
  stage_name     = aws_api_gateway_deployment.stac_server_api_gateway.stage_name
}
