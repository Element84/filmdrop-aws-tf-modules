resource "aws_opensearchserverless_security_policy" "stac_server_opensearch_serverless_encryption_policy" {
  count   = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  name    = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server-ep" : var.opensearch_stac_server_domain_name_override)
  type    = "encryption"
  policy  = jsonencode({
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
  count   = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  name    = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-np" : var.opensearch_stac_server_domain_name_override)
  type    = "network"
  policy  = jsonencode([
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
  count   = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  name    = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-ap" : var.opensearch_stac_server_domain_name_override)
  type    = "data"
  policy  = jsonencode([
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

resource "null_resource" "stac_server_opensearch_serverless_ingest_create_indices" {
  count     = var.deploy_stac_server_opensearch_serverless ? 1 : 0
  triggers = {
    stac_server_ingest = aws_lambda_function.stac_server_ingest.function_name
    opensearch_host    = var.opensearch_host != "" ? var.opensearch_host : var.deploy_stac_server_opensearch_serverless ? aws_opensearchserverless_collection.stac_server_opensearch_serverless_collection[0].collection_endpoint : aws_opensearch_domain.stac_server_opensearch_domain[0].endpoint
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Creating indices on Stac Server OpenSearch Service."
aws lambda invoke --function-name ${aws_lambda_function.stac_server_ingest.function_name} --cli-binary-format raw-in-base64-out --payload '{ "create_indices": true }' output
sleep ${var.stac_server_index_initialization_period}
EOF

  }

  depends_on = [
    aws_lambda_function.stac_server_ingest,
    null_resource.invoke_stac_server_opensearch_user_initializer,
    aws_opensearchserverless_collection.stac_server_opensearch_serverless_collection
  ]
}
