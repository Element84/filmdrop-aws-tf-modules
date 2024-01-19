resource "aws_opensearchserverless_security_policy" "stac_server_opensearch_serverless_encryption_policy" {
  count = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  name  = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server-ep" : var.opensearch_stac_server_domain_name_override)
  type  = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/${lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)}"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_security_policy" "stac_server_opensearch_serverless_network_policy" {
  count = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  name  = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-np" : var.opensearch_stac_server_domain_name_override)
  type  = "network"
  policy = jsonencode([
    {
      Description = "Public access for collection endpoint",
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            "collection/${lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)}"
          ]
        }
      ],
      AllowFromPublic = true,
    },
    {
      Description = "Public access for dashboards",
      Rules = [
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)}"
          ]
        }
      ],
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "stac_server_opensearch_serverless_access_policy" {
  count = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  name  = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-ap" : var.opensearch_stac_server_domain_name_override)
  type  = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index",
          Resource = [
            "index/${lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)}/*"
          ],
          Permission = [
            "aoss:*"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            "collection/${lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)}"
          ],
          Permission = [
            "aoss:*"
          ]
        }
      ],
      Principal = [
        data.aws_caller_identity.current.arn,
        aws_iam_role.stac_api_lambda_role.arn
      ]
    }
  ])

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_opensearchserverless_collection" "stac_server_opensearch_serverless_collection" {
  count       = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  name        = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)
  description = "Stac-server database for ${local.name_prefix}-stac-server"
  type        = "SEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.stac_server_opensearch_serverless_encryption_policy,
    aws_opensearchserverless_security_policy.stac_server_opensearch_serverless_network_policy,
    aws_opensearchserverless_access_policy.stac_server_opensearch_serverless_access_policy
  ]
}

resource "aws_lambda_function" "stac_server_waiting_for_opensearch_serverless_active_collections" {
  count            = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  filename         = data.archive_file.waiting_for_opensearch_lambda_zip.output_path
  source_code_hash = data.archive_file.waiting_for_opensearch_lambda_zip.output_base64sha256
  function_name    = "${local.name_prefix}-stac-server-oss-wait-collections"
  role             = aws_iam_role.stac_api_lambda_role.arn
  description      = "Polls an opensearch serverless collection to ensure it is active prior to attempting to ingest."
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  memory_size      = "512"
  timeout          = "900"

  environment {
    variables = {
      COLLECTION_NAME = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)
      REGION          = data.aws_region.current.name
    }
  }

  depends_on = [
    aws_lambda_function.stac_server_ingest,
    aws_opensearchserverless_security_policy.stac_server_opensearch_serverless_encryption_policy,
    aws_opensearchserverless_security_policy.stac_server_opensearch_serverless_network_policy,
    aws_opensearchserverless_access_policy.stac_server_opensearch_serverless_access_policy,
    aws_opensearchserverless_collection.stac_server_opensearch_serverless_collection
  ]
}

resource "aws_lambda_invocation" "stac_server_opensearch_serverless_wait_for_collections" {
  count         = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  function_name = aws_lambda_function.stac_server_waiting_for_opensearch_serverless_active_collections[0].function_name

  input = "{}"

  depends_on = [
    aws_lambda_function.stac_server_ingest,
    aws_opensearchserverless_security_policy.stac_server_opensearch_serverless_encryption_policy,
    aws_opensearchserverless_security_policy.stac_server_opensearch_serverless_network_policy,
    aws_opensearchserverless_access_policy.stac_server_opensearch_serverless_access_policy,
    aws_opensearchserverless_collection.stac_server_opensearch_serverless_collection,
    aws_lambda_function.stac_server_waiting_for_opensearch_serverless_active_collections
  ]
}


resource "aws_lambda_invocation" "stac_server_opensearch_serverless_ingest_create_indices" {
  count         = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  function_name = aws_lambda_function.stac_server_ingest.function_name

  input = "{ \"create_indices\": true }"

  depends_on = [
    aws_lambda_function.stac_server_ingest,
    aws_opensearchserverless_security_policy.stac_server_opensearch_serverless_encryption_policy,
    aws_opensearchserverless_security_policy.stac_server_opensearch_serverless_network_policy,
    aws_opensearchserverless_access_policy.stac_server_opensearch_serverless_access_policy,
    aws_opensearchserverless_collection.stac_server_opensearch_serverless_collection,
    aws_lambda_function.stac_server_waiting_for_opensearch_serverless_active_collections,
    aws_lambda_invocation.stac_server_opensearch_serverless_wait_for_collections
  ]
}
