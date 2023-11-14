data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_secretsmanager_secret_version" "filmdrop_analytics_credentials_version" {
  secret_id = "${local.kubernetes_cluster_name}-admin-credentials"
}

data "aws_secretsmanager_secret_version" "filmdrop_analytics_dask_secret_token_version" {
  secret_id = "${local.kubernetes_cluster_name}-dask-token"
}

data "archive_file" "cloudfront_origin_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/cloudfront_origin_lambda.zip"
}
