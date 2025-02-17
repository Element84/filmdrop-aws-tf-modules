data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "archive_file" "user_init_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/user_init"
  output_path = "${path.module}/user_init_lambda_zip.zip"
  depends_on = [
    random_string.user_init_lambda_zip_poke
  ]
}

data "archive_file" "waiting_for_opensearch_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/waiting_for_opensearch"
  output_path = "${path.module}/waiting_for_opensearch_lambda_zip.zip"
  depends_on = [
    random_string.user_init_lambda_zip_poke
  ]
}

data "aws_subnet" "selected" {
  count = length(var.vpc_subnet_ids)

  id = var.vpc_subnet_ids[count.index]
}

# this forces the user_init_lambda_zip to always be built
resource "random_string" "user_init_lambda_zip_poke" {
  length  = 16
  special = false
}

locals {
  name_prefix         = "fd-${var.project_name}-${var.stac_api_stage}"
  opensearch_endpoint = var.deploy_stac_server_opensearch_serverless ? aws_opensearchserverless_collection.stac_server_opensearch_serverless_collection[0].collection_endpoint : aws_opensearch_domain.stac_server_opensearch_domain[0].endpoint
  opensearch_domain   = var.deploy_stac_server_opensearch_serverless ? aws_opensearchserverless_collection.stac_server_opensearch_serverless_collection[0].dashboard_endpoint : aws_opensearch_domain.stac_server_opensearch_domain[0].domain_name

  # Resolve the stac-server Lambda ZIP filepaths.
  # Default filepaths are relative to the module and used if a filepath is null.
  # User-provided filepaths are expected to be relative to the root module.
  resolved_api_lambda_zip_filepath = (
    var.api_lambda.zip_filepath == null
    ? "${path.module}/lambda/api/api.zip"
    : "${path.root}/${var.api_lambda.zip_filepath}"
  )
  resolved_ingest_lambda_zip_filepath = (
    var.ingest_lambda.zip_filepath == null
    ? "${path.module}/lambda/ingest/ingest.zip"
    : "${path.root}/${var.ingest_lambda.zip_filepath}"
  )
  resolved_pre_hook_lambda_zip_filepath = (
    var.pre_hook_lambda.zip_filepath == null
    ? "${path.module}/lambda/pre-hook/pre-hook.zip"
    : "${path.root}/${var.pre_hook_lambda.zip_filepath}"
  )
}
