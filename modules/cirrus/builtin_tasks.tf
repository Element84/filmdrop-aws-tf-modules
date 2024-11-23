locals {
  # Pre-batch lambda configuration.
  # Used as input into the Cirrus tasks module.
  pre_batch_task_config = {
    name = "pre-batch"
    lambda = {
      description     = "Cirrus Pre-Batch Lambda"
      filename        = "${path.module}/cirrus-lambda-dist.zip"
      handler         = "pre_batch.lambda_handler"
      runtime         = "python3.12"
      architectures   = ["arm64"]
      publish         = true
      memory_mb       = var.cirrus_pre_batch_lambda_memory
      timeout_seconds = var.cirrus_pre_batch_lambda_timeout
      vpc_enabled     = true

      alarms = (
        var.deploy_alarms
        ? [
          {
            critical            = false
            statistic           = "Sum"
            metric_name         = "Errors"
            comparison_operator = "GreaterThanOrEqualToThreshold"
            threshold           = 10
            period              = 60
            evaluation_periods  = 5
          },
          {
            critical            = true
            statistic           = "Sum"
            metric_name         = "Errors"
            comparison_operator = "GreaterThanOrEqualToThreshold"
            threshold           = 100
            period              = 60
            evaluation_periods  = 5
          }
        ]
        : null
      )

      env_vars = {
        CIRRUS_LOG_LEVEL      = var.cirrus_log_level
        CIRRUS_PAYLOAD_BUCKET = var.cirrus_payload_bucket
      }

      role_statements = [
        {
          sid    = "AllowS3BucketAndObjectRead"
          effect = "Allow"
          actions = [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:GetBucketLocation"
          ]
          resources = ["*"]
        },
        {
          sid       = "AllowCirrusSecretsManagerRead"
          effect    = "Allow"
          actions   = ["secretsmanager:GetSecretValue"]
          resources = ["arn:aws:secretsmanager:${local.current_region}:${local.current_account}:secret:${local.cirrus_prefix}*"]
        },
        {
          sid       = "AllowCirrusPayloadS3BucketWrite"
          effect    = "Allow"
          actions   = ["s3:PutObject"]
          resources = ["arn:aws:s3:::${var.cirrus_payload_bucket}/*"]
        }
      ]
    }
  }

  # Post-batch lambda configuration.
  # Used as input into the Cirrus tasks module.
  post_batch_task_config = {
    name = "post-batch"
    lambda = {
      description     = "Cirrus Post-Batch Lambda"
      filename        = "${path.module}/cirrus-lambda-dist.zip"
      handler         = "post_batch.lambda_handler"
      runtime         = "python3.12"
      architectures   = ["arm64"]
      publish         = true
      memory_mb       = var.cirrus_post_batch_lambda_memory
      timeout_seconds = var.cirrus_post_batch_lambda_timeout
      vpc_enabled     = true

      alarms = (
        var.deploy_alarms
        ? [
          {
            critical            = false
            statistic           = "Sum"
            metric_name         = "Errors"
            comparison_operator = "GreaterThanOrEqualToThreshold"
            threshold           = 10
            period              = 60
            evaluation_periods  = 5
          },
          {
            critical            = true
            statistic           = "Sum"
            metric_name         = "Errors"
            comparison_operator = "GreaterThanOrEqualToThreshold"
            threshold           = 100
            period              = 60
            evaluation_periods  = 5
          }
        ]
        : null
      )

      env_vars = {
        CIRRUS_LOG_LEVEL      = var.cirrus_log_level
        CIRRUS_PAYLOAD_BUCKET = var.cirrus_payload_bucket
      }

      role_statements = [
        {
          sid    = "AllowS3BucketAndObjectRead"
          effect = "Allow"
          actions = [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:GetBucketLocation"
          ]
          resources = ["*"]
        },
        {
          sid       = "AllowCirrusSecretsManagerRead"
          effect    = "Allow"
          actions   = ["secretsmanager:GetSecretValue"]
          resources = ["arn:aws:secretsmanager:${local.current_region}:${local.current_account}:secret:${local.cirrus_prefix}*"]
        },
        {
          sid       = "AllowCirrusPayloadS3BucketWrite"
          effect    = "Allow"
          actions   = ["s3:PutObject"]
          resources = ["arn:aws:s3:::${var.cirrus_payload_bucket}/*"]
        },
        {
          sid       = "AllowBatchLogGroupRead"
          effect    = "Allow"
          actions   = ["logs:GetLogEvents"]
          resources = ["arn:aws:logs:${local.current_region}:${local.current_account}:log-group:/aws/batch/*"]
        }
      ]
    }
  }

  # Convenience list of pre-batch and post-batch task configs
  pre_batch_post_batch_task_configs = [
    local.pre_batch_task_config,
    local.post_batch_task_config
  ]

  # Map of pre-batch and post-batch builtin variables.
  # Allows users to use "${PRE-BATCH}" and "${POST-BATCH}" in workflow templates
  # without any additional config.
  pre_batch_post_batch_task_template_variables = {
    PRE-BATCH = {
      task_name = local.pre_batch_task_config.name
      task_type = "lambda"
      task_attr = "function_arn"
    }
    POST-BATCH = {
      task_name = local.post_batch_task_config.name
      task_type = "lambda"
      task_attr = "function_arn"
    }
  }
}
