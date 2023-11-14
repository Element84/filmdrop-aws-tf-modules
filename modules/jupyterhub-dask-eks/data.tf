data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_secretsmanager_secret_version" "filmdrop_analytics_credentials_version" {
  secret_id     = var.filmdrop_analytics_jupyterhub_admin_credentials_secret
}

data "aws_secretsmanager_secret_version" "filmdrop_analytics_dask_secret_tokens_version" {
  secret_id     = var.filmdrop_analytics_dask_secret_tokens
}
