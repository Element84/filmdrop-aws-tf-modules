resource "aws_opensearch_domain" "stac_server_opensearch_domain" {
  domain_name           = "stac-server-${var.stac_api_stage}"
  engine_version = var.opensearch_version

  cluster_config {
    instance_type             = var.opensearch_cluster_instance_type
    instance_count            = var.opensearch_cluster_instance_count
    dedicated_master_enabled  = var.opensearch_cluster_dedicated_master_enabled
    dedicated_master_type     = var.opensearch_cluster_dedicated_master_type
    zone_awareness_enabled    = var.opensearch_cluster_zone_awareness_enabled

    zone_awareness_config {
      availability_zone_count = var.opensearch_cluster_availability_zone_count
    }
  }

  domain_endpoint_options {
    enforce_https = var.opensearch_domain_enforce_https
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

  dynamic advanced_security_options {
    for_each = var.opensearch_advanced_security_options_enabled == true ? [1] : []
    content {
        enabled                         = var.opensearch_advanced_security_options_enabled
        internal_user_database_enabled  = var.opensearch_internal_user_database_enabled

        dynamic master_user_options {
          for_each = var.opensearch_internal_user_database_enabled == true ? [1] : []

          content {
            master_user_name      = jsondecode(aws_secretsmanager_secret_version.opensearch_master_password_secret_version.secret_string)["username"]
            master_user_password  = jsondecode(aws_secretsmanager_secret_version.opensearch_master_password_secret_version.secret_string)["password"]
          }
        }
    }
  }

  vpc_options {
    subnet_ids          = var.vpc_subnet_ids
    security_group_ids  = [aws_security_group.opensearch_security_group.id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "${var.allow_explicit_index}"
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:ESHttp*",
            "Principal": { "AWS": "*" },
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/stac-server-${var.stac_api_stage}/*"
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
  name        = "stac-server-${var.stac_api_stage}-sg"
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

resource "aws_iam_service_linked_role" "opensearch_linked_role" {
  count             = var.create_opensearch_service_linked_role == true ? 1 : 0
  aws_service_name  = "es.amazonaws.com"
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
   name = "stac-server-${var.stac_api_stage}-master-creds"
}
 
resource "aws_secretsmanager_secret_version" "opensearch_master_password_secret_version" {
  secret_id = aws_secretsmanager_secret.opensearch_master_password_secret.id
  secret_string = <<EOF
   {
    "username": "${var.opensearch_admin_username}",
    "password": "${random_password.opensearch_master_password.result}"
   }
EOF
}

resource "random_password" "opensearch_stac_user_password" {
  length           = 24
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  # opensearch requires at least one special char, but we want to not require
  # URL encoding for the password when it's passed for basic auth in the URL
  override_special = "_-" 
 }

resource "aws_secretsmanager_secret" "opensearch_stac_user_password_secret" {
   name = "stac-server-${var.stac_api_stage}-user-creds"
}

resource "aws_secretsmanager_secret_version" "opensearch_stac_user_password_secret_version" {
  secret_id = aws_secretsmanager_secret.opensearch_stac_user_password_secret.id
  secret_string = <<EOF
   {
    "username": "${var.opensearch_stac_server_username}",
    "password": "${random_password.opensearch_stac_user_password.result}"
   }
EOF
}

# This initializes the stac_server user account and sets OpenSearch configuration.
resource "aws_lambda_function" "stac_server_opensearch_user_initializer" {
  filename         = data.archive_file.user_init_lambda_zip.output_path
  source_code_hash = data.archive_file.user_init_lambda_zip.output_base64sha256
  function_name    = "stac-server-${var.stac_api_stage}-init"
  role             = aws_iam_role.stac_api_lambda_role.arn
  description      = "Lambda function to initialize OpenSearch users, roles, and settings."
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  memory_size      = "512"
  timeout          = "900"

  environment {
    variables = {
        OPENSEARCH_HOST                     = var.opensearch_host != "" ? var.opensearch_host : aws_opensearch_domain.stac_server_opensearch_domain.endpoint
        OPENSEARCH_MASTER_CREDS_SECRET_ARN  = aws_secretsmanager_secret.opensearch_master_password_secret.arn
        OPENSEARCH_USER_CREDS_SECRET_ARN    = aws_secretsmanager_secret.opensearch_stac_user_password_secret.arn
        REGION                              = data.aws_region.current.name
    }
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  depends_on = [
    aws_opensearch_domain.stac_server_opensearch_domain,
    random_password.opensearch_master_password,
    aws_secretsmanager_secret.opensearch_master_password_secret,
    aws_secretsmanager_secret_version.opensearch_master_password_secret_version,
    random_password.opensearch_stac_user_password,
    aws_secretsmanager_secret.opensearch_stac_user_password_secret,
    aws_secretsmanager_secret_version.opensearch_stac_user_password_secret_version
  ]
}

resource "null_resource" "invoke_stac_server_opensearch_user_initializer" {
  triggers = {
    INITIALIZER_LAMBDA                  = aws_lambda_function.stac_server_opensearch_user_initializer.function_name
    OPENSEARCH_HOST                     = aws_opensearch_domain.stac_server_opensearch_domain.endpoint
    OPENSEARCH_MASTER_CREDS_SECRET_ARN  = aws_secretsmanager_secret.opensearch_master_password_secret.arn
    OPENSEARCH_USER_CREDS_SECRET_ARN    = aws_secretsmanager_secret.opensearch_stac_user_password_secret.arn
    REGION                              = data.aws_region.current.name
  }

  provisioner "local-exec" {
command = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Creating stac_server user on OpenSearch cluster."
aws lambda invoke --function-name ${aws_lambda_function.stac_server_opensearch_user_initializer.function_name} --payload '{ }' output

EOF
  }

  depends_on = [
    aws_opensearch_domain.stac_server_opensearch_domain,
    random_password.opensearch_master_password,
    aws_secretsmanager_secret.opensearch_master_password_secret,
    aws_secretsmanager_secret_version.opensearch_master_password_secret_version,
    random_password.opensearch_stac_user_password,
    aws_secretsmanager_secret.opensearch_stac_user_password_secret,
    aws_secretsmanager_secret_version.opensearch_stac_user_password_secret_version,
    aws_lambda_function.stac_server_opensearch_user_initializer
  ]
}
