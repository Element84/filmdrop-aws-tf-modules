locals {
  # Tasks may or may not have a Batch configuration
  create_batch_job = try(var.task_config.batch, null) != null

  # Retrieve the task's specified task_batch_compute module output.
  # This contains all of the information necessary for linking this task to that
  # specific set of Batch resources (job queue, execution role, etc.).
  batch_compute_config = (
    local.create_batch_job
    ? var.cirrus_task_batch_compute[var.task_config.batch.task_batch_compute_name].batch
    : null
  )

  # Gather all user-defined IAM statements needed by the Batch Job / ECS Task
  additional_batch_role_statements = concat(
    try(coalesce(var.task_config.common_role_statements, []), []),
    try(coalesce(var.task_config.batch.role_statements, []), [])
  )

  # Only create an additional policy if role statements were provided
  create_additional_batch_policy = (
    local.create_batch_job
    && length(local.additional_batch_role_statements) > 0
  )
}


# TASK BATCH JOB / ECS TASK IAM ROLE -- BASIC SETUP
# ------------------------------------------------------------------------------
# Creates the role used by the Batch-managed ECS Task.
# This role is always created for Batch tasks as it automatically provides read
# and write permissions on the Cirrus payload bucket; this is necessary for the
# pre-batch and post-batch wrappers used in workflow state machine definitions.
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_batch_assume_role" {
  count = local.create_batch_job ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    # Conditions to prevent the "confused deputy" security problem.
    # Note the "aws:SourceArn" cannot be more strictly defined here as the ECS
    # service's AssumeRole call doesn't always pass a SourceArn containing the
    # cluster name (if it passes one at all).
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ecs:${local.current_region}:${local.current_account}:task/*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

resource "aws_iam_role" "task_batch" {
  count = local.create_batch_job ? 1 : 0

  name_prefix        = "${var.cirrus_prefix}-task-role-"
  description        = "Batch Job / ECS Task role for Cirrus Task '${var.task_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.task_batch_assume_role[0].json
}

data "aws_iam_policy_document" "task_batch_role_payload_bucket_access" {
  # Allow the Batch Job / ECS Task to read/write to the Cirrus payload bucket
  count = local.create_batch_job ? 1 : 0

  statement {
    sid    = "AllowCirrusPayloadBucketList"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.cirrus_payload_bucket}"
    ]
  }

  statement {
    sid    = "AllowCirrusPayloadBucketReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.cirrus_payload_bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy" "task_batch_role_payload_bucket_access" {
  count = local.create_batch_job ? 1 : 0

  name_prefix = "${var.cirrus_prefix}-task-role-payload-policy-"
  role        = aws_iam_role.task_batch[0].name
  policy      = data.aws_iam_policy_document.task_batch_role_payload_bucket_access[0].json
}
# ==============================================================================


# TASK BATCH IAM ROLE -- ADDITIONAL USER INLINE POLICY
# ------------------------------------------------------------------------------
# Optionally creates an inline policy based on input variables
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_batch_role_additional" {
  count = local.create_additional_batch_policy ? 1 : 0

  # Generate a statement block for each object in the input variable.
  # They are all added to this single policy document.
  dynamic "statement" {
    for_each = {
      for statement in local.additional_batch_role_statements :
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

resource "aws_iam_role_policy" "task_batch_role_additional" {
  count = local.create_additional_batch_policy ? 1 : 0

  name_prefix = "${var.cirrus_prefix}-task-role-additional-policy-"
  role        = aws_iam_role.task_batch[0].name
  policy      = data.aws_iam_policy_document.task_batch_role_additional[0].json
}
# ==============================================================================


# TASK BATCH JOB DEFINITION
# ------------------------------------------------------------------------------
resource "aws_batch_job_definition" "task" {
  count = local.create_batch_job ? 1 : 0

  name = "${var.cirrus_prefix}-${var.task_config.name}"

  # Create the container properties JSON.
  # This decodes the user's input JSON string, merges the resulting HCL object
  # with the role ARNs managed by Terraform, then encodes it back to a JSON str.
  container_properties = jsonencode(merge(
    {
      executionRoleArn = local.batch_compute_config.ecs_task_execution_role_arn
      jobRoleArn       = aws_iam_role.task_batch[0].arn
    },
    jsondecode(var.task_config.batch.container_properties)
  ))

  # TODO - CVG
  deregister_on_new_revision = true
  platform_capabilities      = local.batch_compute_config.compute_environment_is_fargate ? ["FARGATE"] : ["EC2"]
  propagate_tags             = true
  scheduling_priority        = var.task_config.batch.scheduling_priority
  type                       = "container"
  parameters                 = var.task_config.batch.parameters

  dynamic "retry_strategy" {
    for_each = (
      var.task_config.batch.retry_strategy != null
    ) ? [var.task_config.batch.retry_strategy] : []
    iterator = retry_strategy

    content {
      attempts = retry_strategy.value.attempts

      dynamic "evaluate_on_exit" {
        for_each = coalesce(retry_strategy.value.evaluate_on_exit, [])
        iterator = eoe

        content {
          action           = eoe.value.action
          on_exit_code     = eoe.value.on_exit_code
          on_reason        = eoe.value.on_reason
          on_status_reason = eoe.value.on_status_reason
        }
      }
    }
  }

  dynamic "timeout" {
    for_each = (
      var.task_config.batch.timeout_seconds != null
    ) ? [var.task_config.batch.timeout_seconds] : []
    iterator = timeout

    content {
      attempt_duration_seconds = timeout.value.timeout_seconds
    }
  }
}
# ==============================================================================