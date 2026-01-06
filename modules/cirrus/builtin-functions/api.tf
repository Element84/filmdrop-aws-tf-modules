locals {
  is_private_endpoint = var.cirrus_api_rest_type == "PRIVATE" ? true : false

  // ensures we use the same var everywhere stage_name of the gateway is needed, and helps avoid ciricular deps
  stage_name = var.cirrus_api_stage
}


resource "aws_iam_role" "cirrus_api_lambda_role" {
  name_prefix = "${var.resource_prefix}-api-role-"

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

data "aws_iam_policy_document" "cirrus_api_lambda_policy_main_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.cirrus_data_bucket}*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${var.resource_prefix}*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      var.cirrus_state_dynamodb_table_arn,
      "${var.cirrus_state_dynamodb_table_arn}/index/*"
    ]
  }
}

data "aws_iam_policy_document" "cirrus_api_lambda_policy_timestream_doc" {
  count = var.workflow_metrics_timestream_enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "timestream:DescribeEndpoints"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "timestream:Select"
    ]
    resources = [
      var.cirrus_state_event_timestreamwrite_table_arn
    ]
  }
}

resource "aws_iam_policy" "cirrus_api_lambda_policy_main" {
  policy = data.aws_iam_policy_document.cirrus_api_lambda_policy_main_doc.json
}

resource "aws_iam_policy" "cirrus_api_lambda_policy_timestream" {
  count  = var.workflow_metrics_timestream_enabled ? 1 : 0
  policy = data.aws_iam_policy_document.cirrus_api_lambda_policy_timestream_doc[0].json
}

resource "aws_iam_role_policy_attachment" "cirrus_api_lambda_role_policy_attachment1" {
  role       = aws_iam_role.cirrus_api_lambda_role.name
  policy_arn = aws_iam_policy.cirrus_api_lambda_policy_main.arn
}

resource "aws_iam_role_policy_attachment" "cirrus_api_lambda_role_policy_attachment2" {
  role       = aws_iam_role.cirrus_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cirrus_api_lambda_role_policy_attachment3" {
  count      = var.workflow_metrics_cloudwatch_enabled ? 1 : 0
  role       = aws_iam_role.cirrus_api_lambda_role.name
  policy_arn = var.workflow_metrics_cloudwatch_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "cirrus_api_lambda_role_policy_attachment4" {
  count      = var.workflow_metrics_timestream_enabled ? 1 : 0
  role       = aws_iam_role.cirrus_api_lambda_role.name
  policy_arn = aws_iam_policy.cirrus_api_lambda_policy_timestream[0].arn
}

resource "aws_lambda_function" "cirrus_api" {
  filename         = local.cirrus_lambda_filename
  function_name    = "${var.resource_prefix}-api"
  description      = "Cirrus API Lambda"
  role             = aws_iam_role.cirrus_api_lambda_role.arn
  handler          = "api.lambda_handler"
  source_code_hash = local.cirrus_lambda_zip_hash
  runtime          = "python${local.cirrus_lambda_pyversion}"
  timeout          = var.cirrus_api_lambda_timeout
  memory_size      = var.cirrus_api_lambda_memory
  publish          = true
  architectures    = ["arm64"]

  environment {
    variables = merge(
      {
        CIRRUS_LOG_LEVEL      = var.cirrus_log_level
        CIRRUS_DATA_BUCKET    = var.cirrus_data_bucket
        CIRRUS_PAYLOAD_BUCKET = var.cirrus_payload_bucket
        CIRRUS_STATE_DB       = var.cirrus_state_dynamodb_table_name
      },
      var.workflow_metrics_timestream_enabled ? {
        CIRRUS_EVENT_DB_AND_TABLE = "${var.cirrus_state_event_timestreamwrite_database_name}|${var.cirrus_state_event_timestreamwrite_table_name}"
      } : {},
      var.workflow_metrics_cloudwatch_enabled ? {
        CIRRUS_WORKFLOW_METRIC_NAMESPACE = var.workflow_metrics_cloudwatch_namespace
      } : {}
    )
  }

  vpc_config {
    security_group_ids = var.vpc_security_group_ids
    subnet_ids         = var.vpc_subnet_ids
  }

  depends_on = [
    null_resource.get_cirrus_lambda
  ]
}

resource "aws_security_group" "cirrus_api_gateway_private_vpce" {
  count = local.is_private_endpoint ? 1 : 0

  name_prefix = "${var.resource_prefix}-apigw-vcpe-sg-"
  description = "Allows TCP inbound on 443 from VPC private subnet CIDRs"

  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "cirrus_api_gateway_private_vpce" {
  for_each = local.is_private_endpoint ? { for s in data.aws_subnet.selected : s.id => s } : {}

  security_group_id = aws_security_group.cirrus_api_gateway_private_vpce[0].id
  description       = "Allow TCP on 443 for subnet ${each.value.id}"

  cidr_ipv4   = each.value.cidr_block
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_endpoint" "cirrus_api_gateway_private" {
  count = local.is_private_endpoint ? 1 : 0

  service_name        = "com.amazonaws.${data.aws_region.current.region}.execute-api"
  vpc_id              = var.vpc_id
  vpc_endpoint_type   = "Interface"
  ip_address_type     = "ipv4"
  subnet_ids          = data.aws_subnet.selected[*].id
  auto_accept         = true
  private_dns_enabled = false
  security_group_ids = concat(
    aws_security_group.cirrus_api_gateway_private_vpce[*].id,
    coalesce(var.cirrus_private_api_additional_security_group_ids, [])
  )

  dns_options {
    dns_record_ip_type = "ipv4"
  }
}

resource "aws_api_gateway_rest_api" "cirrus_api_gateway" {
  name = "${var.resource_prefix}-api"

  endpoint_configuration {
    types            = [var.cirrus_api_rest_type]
    vpc_endpoint_ids = local.is_private_endpoint ? aws_vpc_endpoint.cirrus_api_gateway_private[*].id : null
  }
}

data "aws_iam_policy_document" "cirrus_api_gateway_private" {
  count = local.is_private_endpoint ? 1 : 0

  statement {
    sid       = "DenyApiInvokeForNonVpceTraffic"
    effect    = "Deny"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.cirrus_api_gateway.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      variable = "aws:SourceVpce"
      test     = "StringNotEquals"
      values   = [aws_vpc_endpoint.cirrus_api_gateway_private[0].id]
    }
  }

  statement {
    sid       = "AllowApiInvoke"
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.cirrus_api_gateway.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_api_gateway_rest_api_policy" "cirrus_api_gateway_private" {
  count = local.is_private_endpoint ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.cirrus_api_gateway.id
  policy      = data.aws_iam_policy_document.cirrus_api_gateway_private[0].json
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
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.cirrus_api.arn}/invocations"
  integration_http_method = "POST"
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

resource "aws_api_gateway_integration" "cirrus_api_gateway_proxy_resource_method_integration" {
  rest_api_id             = aws_api_gateway_rest_api.cirrus_api_gateway.id
  resource_id             = aws_api_gateway_resource.cirrus_api_gateway_proxy_resource.id
  http_method             = aws_api_gateway_method.cirrus_api_gateway_proxy_resource_method.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.cirrus_api.arn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "cirrus_api_gateway" {
  depends_on = [
    aws_api_gateway_integration.cirrus_api_gateway_root_method_integration,
    aws_api_gateway_integration.cirrus_api_gateway_proxy_resource_method_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.cirrus_api_gateway.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "cirrus_api_gateway_stage" {
  deployment_id = aws_api_gateway_deployment.cirrus_api_gateway.id
  rest_api_id   = aws_api_gateway_rest_api.cirrus_api_gateway.id
  stage_name    = local.stage_name
  description   = var.cirrus_api_stage_description

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.cirrus_api_gateway_logs_group.arn
    # terraform's jsonencode() sorts keys lexicographically, which would modify the log format. so, we build a string
    # https://github.com/hashicorp/terraform/issues/27880
    format = "{requestId:$context.requestId,ip:$context.identity.sourceIp,caller:$context.identity.caller,user:$context.identity.user,requestTime:$context.requestTime,httpMethod:$context.httpMethod,resourcePath:$context.resourcePath,status:$context.status,protocol:$context.protocol,responseLength:$context.responseLength}"
  }
}

resource "aws_cloudwatch_log_group" "cirrus_api_gateway_logs_group" {
  name = "/aws/apigateway/${var.resource_prefix}-api-${aws_api_gateway_deployment.cirrus_api_gateway.rest_api_id}/${local.stage_name}"
}

resource "aws_lambda_permission" "cirrus_api_gateway_lambda_permission_root_resource" {
  statement_id  = "AllowExecutionFromAPIGatewayRootResource"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cirrus_api.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.cirrus_api_gateway.id}/*/*"
}

resource "aws_lambda_permission" "cirrus_api_gateway_lambda_permission_proxy_resource" {
  statement_id  = "AllowExecutionFromAPIGatewayProxyResource"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cirrus_api.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.cirrus_api_gateway.id}/*/*${aws_api_gateway_resource.cirrus_api_gateway_proxy_resource.path}"
}

resource "aws_cloudwatch_metric_alarm" "cirrus_api_lambda_errors_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${var.resource_prefix}-api Lambda Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 10
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix}-api Cirrus Update-State Lambda Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_api.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_api_lambda_errors_critical_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "CRITICAL: ${var.resource_prefix}-api Lambda Errors Critical Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 100
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.resource_prefix}-api Cirrus Update-State Lambda Errors Critical Alarm"
  alarm_actions             = [var.critical_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_lambda_function.cirrus_api.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_api_gw_errors_warning_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "WARNING: ${aws_api_gateway_rest_api.cirrus_api_gateway.name} API Gateway 5XX Errors Warning Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "5XXError"
  namespace                 = "AWS/ApiGateway"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 10
  treat_missing_data        = "notBreaching"
  alarm_description         = "${aws_api_gateway_rest_api.cirrus_api_gateway.name} Cirrus API Gateway 5XX Errors Warning Alarm"
  alarm_actions             = [var.warning_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_api_gateway_rest_api.cirrus_api_gateway.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cirrus_api_gw_errors_critical_alarm" {
  count                     = var.deploy_alarms ? 1 : 0
  alarm_name                = "CRITICAL: ${aws_api_gateway_rest_api.cirrus_api_gateway.name} API Gateway 5XX Errors Critical Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 5
  metric_name               = "5XXError"
  namespace                 = "AWS/ApiGateway"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 100
  treat_missing_data        = "notBreaching"
  alarm_description         = "${aws_api_gateway_rest_api.cirrus_api_gateway.name} Cirrus API Gateway 5XX Errors Critical Alarm"
  alarm_actions             = [var.critical_sns_topic_arn]
  ok_actions                = [var.warning_sns_topic_arn]
  insufficient_data_actions = []

  dimensions = {
    FunctionName = aws_api_gateway_rest_api.cirrus_api_gateway.name
  }
}

resource "aws_api_gateway_domain_name" "cirrus_api_gateway_domain_name" {
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
      "Resource": "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:/domainnames/*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:/domainnames/*",
      "Condition": {
        "StringNotEquals": {
          "aws:SourceVpce": "${aws_vpc_endpoint.cirrus_api_gateway_private[0].id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_api_gateway_domain_name_access_association" "cirrus_api_gateway_domain_name_access_association" {
  count                          = local.is_private_endpoint == true && var.domain_alias != "" && var.private_certificate_arn != "" ? 1 : 0
  access_association_source      = aws_vpc_endpoint.cirrus_api_gateway_private[0].id
  access_association_source_type = "VPCE"
  domain_name_arn                = aws_api_gateway_domain_name.cirrus_api_gateway_domain_name[0].arn
}

resource "aws_api_gateway_base_path_mapping" "cirrus_api_gateway_domain_mapping" {
  count          = local.is_private_endpoint == true && var.domain_alias != "" && var.private_certificate_arn != "" ? 1 : 0
  domain_name    = aws_api_gateway_domain_name.cirrus_api_gateway_domain_name[0].domain_name
  domain_name_id = aws_api_gateway_domain_name.cirrus_api_gateway_domain_name[0].domain_name_id
  api_id         = aws_api_gateway_rest_api.cirrus_api_gateway.id
  stage_name     = local.stage_name
}
