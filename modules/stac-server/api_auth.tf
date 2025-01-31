resource "aws_lambda_function" "stac_server_api_auth_pre_hook" {
  count = var.stac_server_auth_pre_hook_enabled ? 1 : 0

  filename         = local.resolved_pre_hook_lambda_zip_filepath
  function_name    = "${local.name_prefix}-stac-server-pre-hook"
  description      = "stac-server Auth Pre-Hook Lambda"
  role             = aws_iam_role.stac_api_lambda_role.arn
  handler          = var.pre_hook_lambda.handler
  source_code_hash = filebase64sha256(local.resolved_pre_hook_lambda_zip_filepath)
  runtime          = var.pre_hook_lambda.runtime
  timeout          = var.pre_hook_lambda.timeout_seconds
  memory_size      = var.pre_hook_lambda.memory_mb

  environment {
    variables = {
      API_KEYS_SECRET_ID : one(aws_secretsmanager_secret.stac_server_api_auth_keys[*].arn)
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

resource "null_resource" "cleanup_stac_server_api_auth_keys" {
  count = var.stac_server_auth_pre_hook_enabled ? 1 : 0

  triggers = {
    stac_server_api_auth_keys = "${local.name_prefix}-stac-server-api-auth-keys"
    region                    = data.aws_region.current.name
    account                   = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "FilmDrop Stac Server Secret have been created."

aws secretsmanager describe-secret --secret-id ${self.triggers.stac_server_api_auth_keys}
EOF

  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "Cleaning FilmDrop Stac Server Secret."

aws secretsmanager delete-secret --secret-id ${self.triggers.stac_server_api_auth_keys} --force-delete-without-recovery --region ${self.triggers.region}
EOF
  }


  depends_on = [
    aws_secretsmanager_secret.stac_server_api_auth_keys
  ]
}
