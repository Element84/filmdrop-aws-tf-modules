resource "aws_lambda_function" "stac_server_pre_hook_lambda" {
  count            = var.stac_pre_hook_lambda_path == "" ? 0 : 1
  filename         = var.stac_pre_hook_lambda_path
  function_name    = var.stac_pre_hook_lambda
  description      = "stac-server pre-hook Lambda"
  role             = aws_iam_role.stac_api_lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256(var.stac_pre_hook_lambda_path)
  runtime          = "nodejs16.x"
  timeout          = var.pre_hook_lambda_timeout
  memory_size      = var.pre_hook_lambda_memory

  environment {
    variables = {
        STAC_ID                           = var.stac_id
        STAC_TITLE                        = var.stac_title
        STAC_DESCRIPTION                  = var.stac_description
        STAC_VERSION                      = var.stac_version
        LOG_LEVEL                         = var.log_level
        INGEST_BATCH_SIZE                 = var.opensearch_batch_size
        STAC_DOCS_URL                     = var.stac_docs_url
        OPENSEARCH_HOST                   = var.opensearch_host != "" ? var.opensearch_host : aws_elasticsearch_domain.stac_server_opensearch_domain.endpoint
        ENABLE_TRANSACTIONS_EXTENSION     = var.enable_transactions_extension
        STAC_API_ROOTPATH                 = "/${var.stac_api_stage}"
        PRE_HOOK                          = var.stac_pre_hook_lambda
        PRE_HOOK_AUTH_TOKEN               = var.stac_pre_hook_lambda_token
        PRE_HOOK_AUTH_TOKEN_TXN           = var.stac_pre_hook_lambda_token_txn
        POST_HOOK                         = var.stac_post_hook_lambda
        OPENSEARCH_USERNAME               = var.opensearch_username
        OPENSEARCH_PASSWORD               = var.opensearch_password
        OPENSEARCH_CREDENTIALS_SECRET_ID	= var.opensearch_username == "" ? aws_secretsmanager_secret.opensearch_stac_user_password_secret.arn : null
        ES_COMPAT_MODE                    = var.es_compat_mode
        COLLECTION_TO_INDEX_MAPPINGS      = var.collection_to_index_mappings
    }
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }
}

resource "aws_lambda_function" "stac_server_post_hook_lambda" {
  count            = var.stac_post_hook_lambda_path == "" ? 0 : 1
  filename         = var.stac_post_hook_lambda_path
  function_name    = var.stac_post_hook_lambda
  description      = "stac-server post-hook Lambda"
  role             = aws_iam_role.stac_api_lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256(var.stac_post_hook_lambda_path)
  runtime          = "nodejs16.x"
  timeout          = var.post_hook_lambda_timeout
  memory_size      = var.post_hook_lambda_memory

  environment {
    variables = {
        STAC_ID                           = var.stac_id
        STAC_TITLE                        = var.stac_title
        STAC_DESCRIPTION                  = var.stac_description
        STAC_VERSION                      = var.stac_version
        LOG_LEVEL                         = var.log_level
        INGEST_BATCH_SIZE                 = var.opensearch_batch_size
        STAC_DOCS_URL                     = var.stac_docs_url
        OPENSEARCH_HOST                   = var.opensearch_host != "" ? var.opensearch_host : aws_elasticsearch_domain.stac_server_opensearch_domain.endpoint
        ENABLE_TRANSACTIONS_EXTENSION     = var.enable_transactions_extension
        STAC_API_ROOTPATH                 = "/${var.stac_api_stage}"
        PRE_HOOK                          = var.stac_pre_hook_lambda
        PRE_HOOK_AUTH_TOKEN               = var.stac_pre_hook_lambda_token
        PRE_HOOK_AUTH_TOKEN_TXN           = var.stac_pre_hook_lambda_token_txn
        POST_HOOK                         = var.stac_post_hook_lambda
        OPENSEARCH_USERNAME               = var.opensearch_username
        OPENSEARCH_PASSWORD               = var.opensearch_password
        OPENSEARCH_CREDENTIALS_SECRET_ID	= var.opensearch_username == "" ? aws_secretsmanager_secret.opensearch_stac_user_password_secret.arn : null
        ES_COMPAT_MODE                    = var.es_compat_mode
        COLLECTION_TO_INDEX_MAPPINGS      = var.collection_to_index_mappings
    }
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }
}
