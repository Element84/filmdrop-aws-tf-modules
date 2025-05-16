locals {
  name_prefix = "fd-${var.project_name}-${var.environment}"
}

resource "aws_security_group" "titiler_api_gateway_private_vpce" {
  count = var.is_private_endpoint ? 1 : 0

  name_prefix = "${local.name_prefix}-titiler-api-vcpe-sg-"
  description = "Allows TCP inbound on 443 from VPC private subnet CIDRs"

  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "titiler_api_gateway_private_vcpe" {
  for_each = var.is_private_endpoint ? { for s in data.aws_subnet.selected : s.id => s } : {}

  security_group_id = aws_security_group.titiler_api_gateway_private_vpce[0].id
  description       = "Allow TCP on 443 for subnet ${each.value.id}"

  cidr_ipv4   = each.value.cidr_block
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_endpoint" "titiler_api_gateway_private" {
  count = var.is_private_endpoint ? 1 : 0

  service_name        = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  vpc_id              = var.vpc_id
  vpc_endpoint_type   = "Interface"
  ip_address_type     = "ipv4"
  subnet_ids          = data.aws_subnet.selected[*].id
  auto_accept         = true
  private_dns_enabled = false
  security_group_ids = concat(
    aws_security_group.titiler_api_gateway_private_vpce[*].id,
    coalesce(var.private_api_additional_security_group_ids, [])
  )

  dns_options {
    dns_record_ip_type = "ipv4"
  }
}

resource "aws_api_gateway_rest_api" "titiler_api_gateway" {
  count = var.is_private_endpoint ? 1 : 0
  name  = "${local.name_prefix}-titiler"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = var.is_private_endpoint ? aws_vpc_endpoint.titiler_api_gateway_private[*].id : null
  }
}

data "aws_iam_policy_document" "titiler_api_gateway_private" {
  count = var.is_private_endpoint ? 1 : 0

  statement {
    sid       = "DenyApiInvokeForNonVpceTraffic"
    effect    = "Deny"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.titiler_api_gateway[0].id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      variable = "aws:SourceVpce"
      test     = "StringNotEquals"
      values   = [aws_vpc_endpoint.titiler_api_gateway_private[0].id]
    }
  }

  statement {
    sid       = "AllowApiInvoke"
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.titiler_api_gateway[0].id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_api_gateway_rest_api_policy" "titiler_api_gateway_private" {
  count = var.is_private_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  policy      = data.aws_iam_policy_document.titiler_api_gateway_private[0].json
}

resource "aws_api_gateway_method" "titiler_api_gateway_root_method" {
  count         = var.is_private_endpoint ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id   = aws_api_gateway_rest_api.titiler_api_gateway[0].root_resource_id
  http_method   = "ANY"
  authorization = var.api_method_authorization_type
}

resource "aws_api_gateway_integration" "titiler_api_gateway_root_method_integration" {
  count                   = var.is_private_endpoint ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id             = aws_api_gateway_rest_api.titiler_api_gateway[0].root_resource_id
  http_method             = aws_api_gateway_method.titiler_api_gateway_root_method[0].http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.titiler-mosaic-lambda.arn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_resource" "titiler_api_gateway_proxy_resource" {
  count       = var.is_private_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  parent_id   = aws_api_gateway_rest_api.titiler_api_gateway[0].root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "titiler_api_gateway_proxy_resource_method" {
  count         = var.is_private_endpoint ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id   = aws_api_gateway_resource.titiler_api_gateway_proxy_resource[0].id
  http_method   = "ANY"
  authorization = var.api_method_authorization_type
}

resource "aws_api_gateway_method" "titiler_root_options_method" {
  count         = var.is_private_endpoint ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id   = aws_api_gateway_rest_api.titiler_api_gateway[0].root_resource_id
  http_method   = "OPTIONS"
  authorization = var.api_method_authorization_type
}
resource "aws_api_gateway_method_response" "titiler_root_options_200" {
  count       = var.is_private_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id = aws_api_gateway_rest_api.titiler_api_gateway[0].root_resource_id
  http_method = aws_api_gateway_method.titiler_root_options_method[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "titiler_root_options_integration" {
  count       = var.is_private_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id = aws_api_gateway_rest_api.titiler_api_gateway[0].root_resource_id
  http_method = aws_api_gateway_method.titiler_root_options_method[0].http_method
  type        = "MOCK"
}

resource "aws_api_gateway_integration_response" "titiler_root_options_integration_response" {
  count       = var.is_private_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id = aws_api_gateway_rest_api.titiler_api_gateway[0].root_resource_id
  http_method = aws_api_gateway_method.titiler_root_options_method[0].http_method
  status_code = aws_api_gateway_method_response.titiler_root_options_200[0].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "titiler_options_method" {
  count         = var.is_private_endpoint ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id   = aws_api_gateway_resource.titiler_api_gateway_proxy_resource[0].id
  http_method   = "OPTIONS"
  authorization = var.api_method_authorization_type
}
resource "aws_api_gateway_method_response" "titiler_options_200" {
  count       = var.is_private_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id = aws_api_gateway_resource.titiler_api_gateway_proxy_resource[0].id
  http_method = aws_api_gateway_method.titiler_options_method[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "titiler_options_integration" {
  count       = var.is_private_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id = aws_api_gateway_resource.titiler_api_gateway_proxy_resource[0].id
  http_method = aws_api_gateway_method.titiler_options_method[0].http_method
  type        = "MOCK"
}

resource "aws_api_gateway_integration_response" "titiler_options_integration_response" {
  count       = var.is_private_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id = aws_api_gateway_resource.titiler_api_gateway_proxy_resource[0].id
  http_method = aws_api_gateway_method.titiler_options_method[0].http_method
  status_code = aws_api_gateway_method_response.titiler_options_200[0].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_integration" "titiler_api_gateway_proxy_resource_method_integration" {
  count                   = var.is_private_endpoint ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  resource_id             = aws_api_gateway_resource.titiler_api_gateway_proxy_resource[0].id
  http_method             = aws_api_gateway_method.titiler_api_gateway_proxy_resource_method[0].http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.titiler-mosaic-lambda.arn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "titiler_api_gateway" {
  count = var.is_private_endpoint ? 1 : 0
  depends_on = [
    aws_api_gateway_integration.titiler_api_gateway_root_method_integration,
    aws_api_gateway_integration.titiler_api_gateway_proxy_resource_method_integration,
  ]

  rest_api_id       = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  stage_name        = var.environment
  stage_description = var.titiler_api_stage_description

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "titiler_api_gateway_logs_group" {
  count = var.is_private_endpoint ? 1 : 0
  name  = "/aws/apigateway/${local.name_prefix}-titiler-${aws_api_gateway_deployment.titiler_api_gateway[0].rest_api_id}/${aws_api_gateway_deployment.titiler_api_gateway[0].stage_name}"
}

locals {
  access_log_format = "{\"requestId\":\"\\$context.requestId\",\"ip\":\"\\$context.identity.sourceIp\",\"caller\":\"\\$context.identity.caller\",\"user\":\"\\$context.identity.user\",\"requestTime\":\"\\$context.requestTime\",\"httpMethod\":\"\\$context.httpMethod\",\"resourcePath\":\"\\$context.resourcePath\",\"status\":\"\\$context.status\",\"protocol\":\"\\$context.protocol\",\"responseLength\":\"\\$context.responseLength\"}"
}

resource "null_resource" "enable_access_logs" {
  count = var.is_private_endpoint ? 1 : 0
  triggers = {
    stage_name              = aws_api_gateway_deployment.titiler_api_gateway[0].stage_name
    rest_api_id             = aws_api_gateway_deployment.titiler_api_gateway[0].rest_api_id
    apigw_access_logs_group = aws_cloudwatch_log_group.titiler_api_gateway_logs_group[0].arn
    access_log_format       = local.access_log_format
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Update Access Logging on FilmDrop TiTiler API."
aws apigateway update-stage --rest-api-id ${aws_api_gateway_deployment.titiler_api_gateway[0].rest_api_id} --stage-name ${aws_api_gateway_deployment.titiler_api_gateway[0].stage_name} --patch-operations "[{\"op\": \"replace\",\"path\": \"/accessLogSettings/destinationArn\",\"value\": \"${aws_cloudwatch_log_group.titiler_api_gateway_logs_group[0].arn}\"},{\"op\": \"replace\",\"path\": \"/accessLogSettings/format\",\"value\": \"${local.access_log_format}\"}]"

EOF
  }
}

resource "aws_lambda_permission" "titiler_api_gateway_lambda_permission_root_resource" {
  count         = var.is_private_endpoint ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGatewayRootResource"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.titiler-mosaic-lambda.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.titiler_api_gateway[0].id}/*/*"
}

resource "aws_api_gateway_domain_name" "titiler_api_gateway_domain_name" {
  count           = var.is_private_endpoint == true && var.domain_alias != "" && var.private_certificate_arn != "" ? 1 : 0
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
          "aws:SourceVpce": "${aws_vpc_endpoint.titiler_api_gateway_private[0].id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_api_gateway_domain_name_access_association" "titiler_api_gateway_domain_name_access_association" {
  count                          = var.is_private_endpoint == true && var.domain_alias != "" && var.private_certificate_arn != "" ? 1 : 0
  access_association_source      = aws_vpc_endpoint.titiler_api_gateway_private[0].id
  access_association_source_type = "VPCE"
  domain_name_arn                = aws_api_gateway_domain_name.titiler_api_gateway_domain_name[0].arn
}

resource "aws_api_gateway_base_path_mapping" "titiler_api_gateway_domain_mapping" {
  count          = var.is_private_endpoint == true && var.domain_alias != "" && var.private_certificate_arn != "" ? 1 : 0
  domain_name    = aws_api_gateway_domain_name.titiler_api_gateway_domain_name[0].domain_name
  domain_name_id = aws_api_gateway_domain_name.titiler_api_gateway_domain_name[0].domain_name_id
  api_id         = aws_api_gateway_rest_api.titiler_api_gateway[0].id
  stage_name     = aws_api_gateway_deployment.titiler_api_gateway[0].stage_name
}
