resource "aws_lambda_function" "stac_server_api_auth_pre_hook" {
  count            = var.stac_server_auth_pre_hook_enabled ? 1 : 0
  filename         = "${path.module}/lambda/pre-hook/pre-hook.zip"
  function_name    = "${local.name_prefix}-stac-server-pre-hook"
  description      = "stac-server Auth Pre-Hook Lambda"
  role             = aws_iam_role.stac_api_lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/pre-hook/pre-hook.zip")
  runtime          = "nodejs16.x"
  timeout          = var.pre_hook_lambda_timeout
  memory_size      = var.pre_hook_lambda_memory

  environment {
    variables = {
      API_KEYS_SECRET_ID : one(aws_secretsmanager_secret.stac_server_api_auth_keys[*].arn)
    }
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }
}

resource "aws_secretsmanager_secret" "stac_server_api_auth_keys" {
  count = var.stac_server_auth_pre_hook_enabled ? 1 : 0
  name  = "${local.name_prefix}-stac-server-api-auth-keys"
}

resource "aws_secretsmanager_secret_version" "stac_server_api_auth_keys_version" {
  count         = var.stac_server_auth_pre_hook_enabled ? 1 : 0
  secret_id     = one(aws_secretsmanager_secret.stac_server_api_auth_keys[*].id)
  secret_string = "{}"
  lifecycle {
    ignore_changes = [secret_string, secret_binary]
  }
}
