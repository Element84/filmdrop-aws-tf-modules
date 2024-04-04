resource "random_id" "suffix" {
  byte_length = 8
}

resource "aws_opensearch_domain" "stac_server_opensearch_domain" {
  count          = var.deploy_stac_server_opensearch_serverless ? 0 : 1
  domain_name    = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)
  engine_version = var.opensearch_version

  cluster_config {
    instance_type            = var.opensearch_cluster_instance_type
    instance_count           = var.opensearch_cluster_instance_count
    dedicated_master_enabled = var.opensearch_cluster_dedicated_master_enabled
    dedicated_master_type    = var.opensearch_cluster_dedicated_master_type
    dedicated_master_count   = var.opensearch_cluster_dedicated_master_count
    zone_awareness_enabled   = var.opensearch_cluster_zone_awareness_enabled

    zone_awareness_config {
      availability_zone_count = var.opensearch_cluster_availability_zone_count
    }
  }

  domain_endpoint_options {
    enforce_https       = var.opensearch_domain_enforce_https
    tls_security_policy = var.opensearch_domain_min_tls
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.opensearch_ebs_volume_size
    volume_type = var.opensearch_ebs_volume_type
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  dynamic "advanced_security_options" {
    for_each = var.opensearch_advanced_security_options_enabled == true ? [1] : []
    content {
      enabled                        = var.opensearch_advanced_security_options_enabled
      internal_user_database_enabled = var.opensearch_internal_user_database_enabled

      dynamic "master_user_options" {
        for_each = var.opensearch_internal_user_database_enabled == true ? [1] : []

        content {
          master_user_name     = jsondecode(aws_secretsmanager_secret_version.opensearch_master_password_secret_version.secret_string)["username"]
          master_user_password = jsondecode(aws_secretsmanager_secret_version.opensearch_master_password_secret_version.secret_string)["password"]
        }
      }
    }
  }

  dynamic "vpc_options" {
    for_each = { for i, j in [var.deploy_stac_server_outside_vpc] : i => j if var.deploy_stac_server_outside_vpc != true }

    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = [aws_security_group.opensearch_security_group[0].id]
    }
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = var.allow_explicit_index
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": { "AWS": "*" },
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${lower(local.name_prefix)}-stac-server/*"
        }
    ]
}
CONFIG


  lifecycle {
    ignore_changes  = [access_policies]
    prevent_destroy = true
  }

  depends_on = [
    random_password.opensearch_master_password,
    aws_secretsmanager_secret.opensearch_master_password_secret,
    aws_secretsmanager_secret_version.opensearch_master_password_secret_version,
    random_password.opensearch_stac_user_password,
    aws_secretsmanager_secret.opensearch_stac_user_password_secret,
    aws_secretsmanager_secret_version.opensearch_stac_user_password_secret_version
  ]
}

resource "aws_security_group" "opensearch_security_group" {
  count       = var.deploy_stac_server_opensearch_serverless ? 0 : 1
  name_prefix = "${local.name_prefix}-stac-server"
  description = "OpenSearch Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_range]
    description = "Inbound VPC Access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound Access"
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "random_password" "opensearch_master_password" {
  length           = 16
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "opensearch_master_password_secret" {
  name = "${local.name_prefix}-stac-server-master-creds-${random_id.suffix.hex}"
}

resource "aws_secretsmanager_secret_version" "opensearch_master_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.opensearch_master_password_secret.id
  secret_string = <<EOF
   {
    "username": "${var.opensearch_admin_username}",
    "password": "${random_password.opensearch_master_password.result}"
   }
EOF
}

resource "null_resource" "cleanup_opensearch_master_password_secret" {
  triggers = {
    opensearch_master_password_secret = "${local.name_prefix}-stac-server-master-creds-${random_id.suffix.hex}"
    region                            = data.aws_region.current.name
    account                           = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "FilmDrop Stac Server Secret have been created."

aws secretsmanager describe-secret --secret-id ${self.triggers.opensearch_master_password_secret}
EOF

  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "Cleaning FilmDrop Stac Server Secret."

aws secretsmanager delete-secret --secret-id ${self.triggers.opensearch_master_password_secret} --force-delete-without-recovery --region ${self.triggers.region}
EOF
  }


  depends_on = [
    aws_secretsmanager_secret.opensearch_master_password_secret
  ]
}

resource "random_password" "opensearch_stac_user_password" {
  length      = 24
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  # opensearch requires at least one special char, but we want to not require
  # URL encoding for the password when it's passed for basic auth in the URL
  override_special = "_-"
}

resource "aws_secretsmanager_secret" "opensearch_stac_user_password_secret" {
  name = "${local.name_prefix}-stac-server-user-creds-${random_id.suffix.hex}"
}

resource "aws_secretsmanager_secret_version" "opensearch_stac_user_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.opensearch_stac_user_password_secret.id
  secret_string = <<EOF
   {
    "username": "${var.opensearch_stac_server_username}",
    "password": "${random_password.opensearch_stac_user_password.result}"
   }
EOF
}

resource "null_resource" "cleanup_opensearch_stac_user_password_secret" {
  triggers = {
    opensearch_stac_user_password_secret = "${local.name_prefix}-stac-server-user-creds-${random_id.suffix.hex}"
    region                               = data.aws_region.current.name
    account                              = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "FilmDrop Stac Server Secret have been created."

aws secretsmanager describe-secret --secret-id ${self.triggers.opensearch_stac_user_password_secret}
EOF

  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "Cleaning FilmDrop Stac Server Secret."

aws secretsmanager delete-secret --secret-id ${self.triggers.opensearch_stac_user_password_secret} --force-delete-without-recovery --region ${self.triggers.region}
EOF
  }


  depends_on = [
    aws_secretsmanager_secret.opensearch_stac_user_password_secret
  ]
}

# This initializes the stac_server user account and sets OpenSearch configuration.
resource "aws_lambda_function" "stac_server_opensearch_user_initializer" {
  filename         = data.archive_file.user_init_lambda_zip.output_path
  source_code_hash = data.archive_file.user_init_lambda_zip.output_base64sha256
  function_name    = "${local.name_prefix}-stac-server-init"
  role             = aws_iam_role.stac_api_lambda_role.arn
  description      = "Lambda function to initialize OpenSearch users, roles, and settings."
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  memory_size      = "512"
  timeout          = "900"

  environment {
    variables = {
      OPENSEARCH_HOST                    = var.opensearch_host != "" ? var.opensearch_host : local.opensearch_endpoint
      OPENSEARCH_MASTER_CREDS_SECRET_ARN = aws_secretsmanager_secret.opensearch_master_password_secret.arn
      OPENSEARCH_USER_CREDS_SECRET_ARN   = aws_secretsmanager_secret.opensearch_stac_user_password_secret.arn
      REGION                             = data.aws_region.current.name
    }
  }

  dynamic "vpc_config" {
    for_each = { for i, j in [var.deploy_stac_server_outside_vpc] : i => j if var.deploy_stac_server_outside_vpc != true }

    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  depends_on = [
    random_password.opensearch_master_password,
    aws_secretsmanager_secret.opensearch_master_password_secret,
    aws_secretsmanager_secret_version.opensearch_master_password_secret_version,
    random_password.opensearch_stac_user_password,
    aws_secretsmanager_secret.opensearch_stac_user_password_secret,
    aws_secretsmanager_secret_version.opensearch_stac_user_password_secret_version,
    data.archive_file.user_init_lambda_zip
  ]
}

resource "aws_lambda_invocation" "invoke_stac_server_opensearch_user_initializer" {
  count         = var.deploy_stac_server_opensearch_serverless ? 0 : 1
  function_name = aws_lambda_function.stac_server_opensearch_user_initializer.function_name

  input = "{}"

  depends_on = [
    random_password.opensearch_master_password,
    aws_secretsmanager_secret.opensearch_master_password_secret,
    aws_secretsmanager_secret_version.opensearch_master_password_secret_version,
    random_password.opensearch_stac_user_password,
    aws_secretsmanager_secret.opensearch_stac_user_password_secret,
    aws_secretsmanager_secret_version.opensearch_stac_user_password_secret_version,
    aws_lambda_function.stac_server_opensearch_user_initializer
  ]
}

resource "aws_lambda_invocation" "stac_server_opensearch_domain_ingest_create_indices" {
  count         = var.deploy_stac_server_opensearch_serverless ? 0 : 1
  function_name = aws_lambda_function.stac_server_ingest.function_name

  input = "{ \"create_indices\": true }"

  depends_on = [
    aws_lambda_function.stac_server_ingest,
    aws_lambda_invocation.invoke_stac_server_opensearch_user_initializer,
    aws_opensearch_domain.stac_server_opensearch_domain
  ]
}
