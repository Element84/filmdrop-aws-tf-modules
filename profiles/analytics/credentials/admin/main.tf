resource "random_password" "filmdrop_analytics_credentials" {
  length  = 16
  special = false
}

resource "random_password" "filmdrop_analytics_dask_secret_token_proxy_token" {
  length  = 16
  special = false
  upper   = false
}

resource "random_password" "filmdrop_analytics_dask_secret_token_api_token" {
  length  = 16
  special = false
  upper   = false
}

resource "aws_secretsmanager_secret" "filmdrop_analytics_credentials" {
  name = "${var.credentials_name_prefix}-admin-credentials"
}

resource "aws_secretsmanager_secret_version" "filmdrop_analytics_credentials_version" {
  secret_id = aws_secretsmanager_secret.filmdrop_analytics_credentials.id
  secret_string = jsonencode({
    USERNAME = "admin"
    PASSWORD = random_password.filmdrop_analytics_credentials.result
  })

  lifecycle {
    ignore_changes = [secret_string, secret_binary]
  }
}

resource "aws_secretsmanager_secret" "filmdrop_analytics_dask_secret_token" {
  name = "${var.credentials_name_prefix}-dask-token"
}

resource "aws_secretsmanager_secret_version" "filmdrop_analytics_dask_secret_token_version" {
  secret_id = aws_secretsmanager_secret.filmdrop_analytics_dask_secret_token.id
  secret_string = jsonencode({
    PROXYTOKEN = random_password.filmdrop_analytics_dask_secret_token_proxy_token.result
    APITOKEN   = random_password.filmdrop_analytics_dask_secret_token_api_token.result
  })

  lifecycle {
    ignore_changes = [secret_string, secret_binary]
  }
}
