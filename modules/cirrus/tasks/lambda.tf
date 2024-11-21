locals {
  # Tasks may or may not have a Lambda configuration
  create_lambda = (var.task_config.lambda != null)

  # Gather all user-defined IAM statements needed by the Lambda execution role
  task_lambda_role_statements = (
    local.create_lambda
    ? concat(
      try(coalesce(var.task_config.common_role_statements, []), []),
      try(coalesce(var.task_config.lambda.role_statements, []), [])
    )
    : []
  )

  # Create the Lambda function name.
  # This is needed by the Lambda execution role prior to function creation, so a
  # resource reference cannot be used.
  task_lambda_function_name = "${var.cirrus_prefix}-${var.task_config.name}"

  # Lambdas running within the VPC will require additional permissions
  deploy_lambda_in_vpc = (
    local.create_lambda
    && try(coalesce(var.task_config.lambda.vpc_enabled, true), true)
  )
}


# TASK LAMBDA IAM ROLE -- BASIC SETUP
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_lambda_assume_role_policy" {
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
      values   = ["${local.current_account}"]
    }
  }
}

resource "aws_iam_role" "task_lambda" {
  count = local.create_lambda ? 1 : 0

  name_prefix        = "${var.cirrus_prefix}-task-role-"
  description        = "Lambda execution role for Cirrus Task '${var.task_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.task_lambda_assume_role_policy[0].json
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


# TASK LAMBDA IAM ROLE -- ADDITIONAL INLINE POLICY
# ------------------------------------------------------------------------------
# Optionally creates an inline policy based on user input variables
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_lambda_additional_role_policy" {
  # If one or more role statements were provided, this document is created
  count = (
    local.create_lambda
    && length(local.task_lambda_role_statements) > 0
  ) ? 1 : 0

  # Generate a statement block for each object in the input variable.
  # They are all added to this single policy document.
  dynamic "statement" {
    for_each = {
      for _, statement in local.task_lambda_role_statements :
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

resource "aws_iam_role_policy" "task_lambda_additional_role_policy" {
  count = (
    local.create_lambda
    && length(local.task_lambda_role_statements) > 0
  ) ? 1 : 0

  name_prefix = "${var.cirrus_prefix}-task-role-additional-policy-"
  role        = aws_iam_role.task_lambda[0].name
  policy      = data.aws_iam_policy_document.task_lambda_additional_role_policy[0].json
}
# ==============================================================================


# TASK LAMBDA FUNCTION -- ZIP OR IMAGE BASED
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "task_lambda" {
  count = local.create_lambda ? 1 : 0

  function_name = local.task_lambda_function_name
  description   = var.task_config.lambda.description
  role          = aws_iam_role.task_lambda[0].arn
  package_type  = var.task_config.lambda.ecr_image_uri != null ? "Image" : "Zip"
  image_uri     = var.task_config.lambda.ecr_image_uri
  s3_bucket     = var.task_config.lambda.s3_bucket
  s3_key        = var.task_config.lambda.s3_key
  handler       = var.task_config.lambda.handler
  runtime       = var.task_config.lambda.runtime
  architectures = var.task_config.lambda.architectures
  memory_size   = var.task_config.lambda.memory_mb
  timeout       = var.task_config.lambda.timeout_seconds
  publish       = var.task_config.lambda.publish

  # Optional value stored as a configuration block.
  # A single instance is created only if 'env_vars' was provided.
  dynamic "environment" {
    for_each = var.task_config.lambda.env_vars != null ? [1] : []
    content {
      variables = {
        for k, v in var.task_config.lambda.env_vars : k => v
      }
    }
  }

  # Optional value stored as a configuration block.
  # A single instance is created only if 'image_config' was provided.
  dynamic "image_config" {
    for_each = var.task_config.lambda.image_config != null ? [1] : []
    content {
      command           = var.task_config.lambda.image_config.command
      entry_point       = var.task_config.lambda.image_config.entry_point
      working_directory = var.task_config.lambda.image_config.working_directory
    }
  }

  # Optional value stored as a configuration block.
  # A single instance is created only if 'vpc_config' was provided.
  dynamic "vpc_config" {
    for_each = local.deploy_lambda_in_vpc ? [1] : []
    content {
      security_group_ids = var.vpc_security_group_ids
      subnet_ids         = var.vpc_subnet_ids
    }
  }

  # Dependent on all IAM policies being created/attached to the role first
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_read_only,
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_iam_role_policy.task_lambda_additional_role_policy
  ]
}
# ==============================================================================


# TASK LAMBDA CLOUDWATCH ALARMS
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "task_lambda" {
  # Create a cloudwatch alarm for each provided configuration object.
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
    "${var.cirrus_prefix}-${var.task_config.name}-task-lambda",
    lower(each.value.metric_name),
    lower(each.value.statistic),
    each.value.critical ? "critical" : "warning"
  )

  alarm_description = format(
    "%s %s %s %s Alarm",
    "${var.cirrus_prefix}-${var.task_config.name} Task Lambda",
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
    FunctionName = aws_lambda_function.task_lambda[0].arn
  }
}
# ==============================================================================