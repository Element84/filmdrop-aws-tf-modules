locals {
  # Tasks may or may not have a Lambda configuration
  create_lambda = (var.task_config.lambda != null)

  # Gather all user-defined IAM statements needed by the Lambda execution role
  additional_lambda_role_statements = (
    local.create_lambda
    ? concat(
      try(coalesce(var.task_config.common_role_statements, []), []),
      try(coalesce(var.task_config.lambda.role_statements, []), [])
    )
    : []
  )

  # Only create an additional policy if role statements were provided
  create_additional_lambda_policy = (
    local.create_lambda
    && length(local.additional_lambda_role_statements) > 0
  )

  # Create the Lambda function name.
  # This is needed by the Lambda execution role prior to function creation, so a
  # resource reference cannot be used.
  task_lambda_function_name = "${var.resource_prefix}-${var.task_config.name}"

  # Lambdas running within the VPC will require additional permissions
  deploy_lambda_in_vpc = (
    local.create_lambda
    && try(coalesce(var.task_config.lambda.vpc_enabled, true), true)
  )
}


# TASK LAMBDA -- RESOLVING ECR IMAGE TAG TO DIGEST
# ------------------------------------------------------------------------------
# Image-based lambdas must source images from ECR.
# To support mutable tags, the following will optionally retrieve the latest
# digest for the targeted image tag in order to force a lambda function update
# during the next deployment.  Terraform will not check for a tag's targeted
# digest otherwise.
# ------------------------------------------------------------------------------
locals {
  # Determine if the image is ECR-based and capture details via regex groups
  lambda_ecr_image_details = (
    local.create_lambda
    && try(var.task_config.lambda.ecr_image_uri, null) != null
    ? try(regex(local.ecr_image_regex, var.task_config.lambda.ecr_image_uri), null)
    : null
  )

  # Determine if we need to get the latest digest for the given tag
  lambda_resolve_ecr_tag_to_digest = (
    local.lambda_ecr_image_details != null
    && try(var.task_config.lambda.resolve_ecr_tag_to_digest, false) == true
  )
}

data "aws_ecr_image" "lambda_task_image" {
  count = local.lambda_resolve_ecr_tag_to_digest ? 1 : 0

  repository_name = local.lambda_ecr_image_details.repository
  image_tag       = local.lambda_ecr_image_details.tag
  registry_id     = local.lambda_ecr_image_details.account_id
}
# ==============================================================================


# TASK LAMBDA IAM ROLE -- BASIC SETUP
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_lambda_assume_role" {
  count = local.create_lambda ? 1 : 0

  statement {
    sid     = "LambdaServiceAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    # Conditions to prevent the "confused deputy" security problem
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:lambda:${local.current_region}:${local.current_account}:function:${local.task_lambda_function_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

resource "aws_iam_role" "task_lambda" {
  count = local.create_lambda ? 1 : 0

  name_prefix        = "${var.resource_prefix}-task-role-"
  description        = "Lambda execution role for Cirrus Task '${var.task_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.task_lambda_assume_role[0].json
}
# ==============================================================================


# TASK LAMBDA IAM ROLE -- MANAGED POLICY ATTACHMENTS
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count = local.create_lambda ? 1 : 0

  role       = aws_iam_role.task_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_read_only" {
  count = local.create_lambda ? 1 : 0

  role       = aws_iam_role.task_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  count = (local.create_lambda && local.deploy_lambda_in_vpc) ? 1 : 0

  role       = aws_iam_role.task_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
# ==============================================================================


# TASK LAMBDA IAM ROLE -- ADDITIONAL USER INLINE POLICY
# ------------------------------------------------------------------------------
# Optionally creates an inline policy based on user input variables
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_lambda_role_additional" {
  # If one or more role statements were provided, this document is created
  count = local.create_additional_lambda_policy ? 1 : 0

  # Generate a statement block for each object in the input variable.
  # They are all added to this single policy document.
  dynamic "statement" {
    for_each = {
      for statement in local.additional_lambda_role_statements :
      statement.sid => statement
    }

    content {
      # Required values
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      # Optional values
      not_actions   = try(statement.value.not_actions, null)
      not_resources = try(statement.value.not_resources, null)

      # Optional value stored as a configuration block.
      # A single instance is created only if 'condition' was provided.
      dynamic "condition" {
        for_each = (
          try(statement.value.condition, null) != null
        ) ? [statement.value.condition] : []

        content {
          # If 'condition' was provided, it must contain these values
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }

      # Optional value stored as a configuration block.
      # A single instance is created only if 'principals' was provided.
      dynamic "principals" {
        for_each = (
          try(statement.value.principals, null) != null
        ) ? [statement.value.principals] : []

        content {
          # If 'principals' was provided, it must contain these values
          identifiers = principals.value.identifiers
          type        = principals.value.type
        }
      }

      # Optional value stored as a configuration block.
      # A single instance is created only if 'not_principals' was provided.
      dynamic "not_principals" {
        for_each = (
          try(statement.value.not_principals, null) != null
        ) ? [statement.value.not_principals] : []

        content {
          # If 'not_principals' was provided, it must contain these values
          identifiers = not_principals.value.identifiers
          type        = not_principals.value.type
        }
      }
    }
  }
}

resource "aws_iam_role_policy" "task_lambda_role_additional" {
  count = local.create_additional_lambda_policy ? 1 : 0

  name_prefix = "${var.resource_prefix}-task-role-additional-policy-"
  role        = aws_iam_role.task_lambda[0].name
  policy      = data.aws_iam_policy_document.task_lambda_role_additional[0].json
}
# ==============================================================================


# TASK LAMBDA FUNCTION -- REMOTE ZIP, LOCAL ZIP, OR IMAGE BASED
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "task" {
  count = local.create_lambda ? 1 : 0

  function_name = local.task_lambda_function_name

  architectures = var.task_config.lambda.architectures
  description   = var.task_config.lambda.description
  handler       = var.task_config.lambda.handler
  image_uri     = var.task_config.lambda.ecr_image_uri
  memory_size   = var.task_config.lambda.memory_mb
  package_type  = var.task_config.lambda.ecr_image_uri != null ? "Image" : "Zip"
  publish       = var.task_config.lambda.publish
  role          = aws_iam_role.task_lambda[0].arn
  runtime       = var.task_config.lambda.runtime
  s3_bucket     = var.task_config.lambda.s3_bucket
  s3_key        = var.task_config.lambda.s3_key
  timeout       = var.task_config.lambda.timeout_seconds

  # Local ZIP handling.
  # Path is expected to be relative to the ROOT module of this deployment.
  filename = (
    var.task_config.lambda.filename != null
    ? "${path.root}/${var.task_config.lambda.filename}"
    : null
  )

  # Trigger function updates whenever the source updates.
  # This could be a file update or a newer ECR image hash for a given tag.
  source_code_hash = (
    var.task_config.lambda.filename != null
    ? filebase64sha256("${path.root}/${var.task_config.lambda.filename}")
    : local.lambda_resolve_ecr_tag_to_digest
    ? base64sha256(data.aws_ecr_image.lambda_task_image[0].image_digest)
    : null
  )

  # Create zero or one environment configuration blocks
  dynamic "environment" {
    for_each = var.task_config.lambda.env_vars != null ? [1] : []
    content {
      variables = {
        for k, v in var.task_config.lambda.env_vars : k => v
      }
    }
  }

  # Create zero or one image configuration blocks
  dynamic "image_config" {
    for_each = var.task_config.lambda.image_config != null ? [1] : []
    content {
      command           = var.task_config.lambda.image_config.command
      entry_point       = var.task_config.lambda.image_config.entry_point
      working_directory = var.task_config.lambda.image_config.working_directory
    }
  }

  # Create zero or one VPC configuration blocks
  dynamic "vpc_config" {
    for_each = local.deploy_lambda_in_vpc ? [1] : []
    content {
      security_group_ids = var.vpc_security_group_ids
      subnet_ids         = var.vpc_subnet_ids
    }
  }

  # Create zero or one ephemeral storage configuration blocks
  dynamic "ephemeral_storage" {
    for_each = var.task_config.lambda.ephemeral_storage_mb != null ? [1] : []
    content {
      size = var.task_config.lambda.ephemeral_storage_mb
    }
  }

  # Dependent on all IAM policies being created/attached to the role first
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_read_only,
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_iam_role_policy.task_lambda_role_additional
  ]
}
# ==============================================================================


# TASK LAMBDA CLOUDWATCH ALARMS
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "task_lambda" {
  # Create a cloudwatch alarm for each provided configuration object
  for_each = (
    (
      local.create_lambda
      && try(var.task_config.lambda.alarms, null) != null
    )
    ? { for index, alarm in var.task_config.lambda.alarms : index => alarm }
    : tomap({})
  )

  alarm_name = format(
    "%s-%s-%s-%s-alarm",
    "${var.resource_prefix}-${var.task_config.name}-task-lambda",
    lower(each.value.metric_name),
    lower(each.value.statistic),
    each.value.critical ? "critical" : "warning"
  )

  alarm_description = format(
    "%s %s %s %s Alarm",
    "${var.resource_prefix}-${var.task_config.name} Task Lambda",
    "${each.value.metric_name} ${each.value.statistic}",
    "${each.value.comparison_operator} ${each.value.threshold}",
    each.value.critical ? "Critical" : "Warning"
  )

  namespace                 = "AWS/Lambda"
  statistic                 = each.value.statistic
  metric_name               = each.value.metric_name
  comparison_operator       = each.value.comparison_operator
  threshold                 = each.value.threshold
  period                    = each.value.period
  evaluation_periods        = each.value.evaluation_periods
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  ok_actions                = [var.warning_sns_topic_arn]
  alarm_actions = (
    each.value.critical
    ? [var.critical_sns_topic_arn]
    : [var.warning_sns_topic_arn]
  )

  dimensions = {
    FunctionName = aws_lambda_function.task[0].arn
  }
}
# ==============================================================================
