# TODO - CVG - file docstring
# TODO - CVG - reinforce task name uniqueness
# TODO - CVG - auto-permit basic payload and data bucket reads?
# TODO - CVG - name prefix length limits?

locals {
  # Reformat the task name for consistency
  task_name = lower(replace(var.task_config.name, "/[\\._\\s]/", "-"))
}


# TASK LAMBDA IAM ROLE - BASIC SETUP
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_lambda_assume_role_policy" {
  count = var.task_config.lambda != null ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "task_lambda" {
  count = var.task_config.lambda != null ? 1 : 0

  name_prefix        = "${var.cirrus_prefix}-task-role-"
  description        = "Lambda execution role for Cirrus Task '${local.task_name}'"
  assume_role_policy = data.aws_iam_policy_document.task_lambda_assume_role_policy[0].json
}
# ==============================================================================


# TASK LAMBDA IAM ROLE - MANAGED POLICY ATTACHMENTS
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count = var.task_config.lambda != null ? 1 : 0

  role       = aws_iam_role.task_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_read_only" {
  count = var.task_config.lambda != null ? 1 : 0

  role       = aws_iam_role.task_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  count = (var.task_config.lambda != null && var.task_config.lambda.vpc_enabled) ? 1 : 0

  role       = aws_iam_role.task_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
# ==============================================================================


# TASK LAMBDA IAM ROLE -- ADDITIONAL INLINE POLICY
# Optionally creates an inline policy based on input variables
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_lambda_additional_role_policy" {
  # If one or more role statements were provided, this document is created
  count = (
    try(var.task_config.lambda.role_statements, null) != null
    && length(var.task_config.lambda.role_statements) > 0
  ) ? 1 : 0

  # Generate a statement block for each object in the input variable.
  # They are all added to this single policy document.
  dynamic "statement" {
    for_each = {
      for _, statement in var.task_config.lambda.role_statements :
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
  count = length(data.aws_iam_policy_document.task_lambda_additional_role_policy)

  name_prefix = "${var.cirrus_prefix}-task-role-additional-policy-"
  role        = aws_iam_role.task_lambda[0].name
  policy      = data.aws_iam_policy_document.task_lambda_additional_role_policy[0].json
}
# ==============================================================================


# TASK LAMBDA FUNCTION -- ZIP OR IMAGE BASED
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "task_lambda" {
  count = var.task_config.lambda != null ? 1 : 0

  function_name = "${var.cirrus_prefix}-${local.task_name}"
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
    for_each = var.task_config.lambda.vpc_enabled ? [1] : []
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


# TASK LAMBDA CLOUDWATCH ALARMS - WARNING AND CRITICAL
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "task_lambda" {
  for_each = {
    for index, alarm in(
      try(var.task_config.lambda.alarms, null) != null
      ? var.task_config.lambda.alarms
      : []
    ) :
    index => alarm
  }

  alarm_name = format(
    "%s-%s-%s-%s-alarm",
    "${var.cirrus_prefix}-${local.task_name}-task-lambda",
    lower(each.value.metric_name),
    lower(each.value.statistic),
    each.value.critical ? "critical" : "warning"
  )

  alarm_description = format(
    "%s %s %s %s Alarm",
    "${var.cirrus_prefix}-${local.task_name} Task Lambda",
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