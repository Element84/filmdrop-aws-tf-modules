data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name

  # Create the workflow's state machine JSON.
  # Use the Cirrus task output map, user-defined template variable map, and
  # builtin template variable map for interpolation. Decode the rendered JSON to
  # strip newlines then encode to minify.
  workflow_state_machine_json = jsonencode(jsondecode(templatefile(
    "${path.root}/${var.workflow_config.state_machine_filepath}",
    merge(
      { tasks = var.cirrus_tasks },
      var.workflow_definitions_variables,
      var.builtin_workflow_definitions_variables
    )
  )))

  # Gather any referenced Lambda Function ARNs.
  # These are needed for generating the workflow machine's IAM policies.
  # This includes both Cirrus- and non-Cirrus-managed Lambdas, if any.
  workflow_tasks_lambda_functions = distinct(regexall(
    "arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9_-]+",
    local.workflow_state_machine_json
  ))

  # Gather any referenced Job Queue and Definition ARNs.
  # These are needed for generating the workflow machine's IAM policies.
  # Job definition ARNs add a wildcard suffix for the version number.
  workflow_tasks_batch_job_resources = [
    for job_def in distinct(regexall(
      "arn:aws:batch:[a-z0-9-]+:[0-9]{12}:job-definition/[a-zA-Z0-9_-]+",
      local.workflow_state_machine_json
    )) : format("%s:*", job_def)
  ]
  workflow_tasks_batch_queue_resources = distinct(regexall(
    "arn:aws:batch:[a-z0-9-]+:[0-9]{12}:job-queue/[a-zA-Z0-9_-]+",
    local.workflow_state_machine_json
  ))
  workflow_tasks_batch_resources = concat(
    local.workflow_tasks_batch_job_resources,
    local.workflow_tasks_batch_queue_resources
  )

  # Submit/Invoke permissions only necessary if Batch/Lambda resources are used
  create_batch_policy  = (length(local.workflow_tasks_batch_resources) != 0)
  create_lambda_policy = (length(local.workflow_tasks_lambda_functions) != 0)

  # Only create an additional policy if role statements were provided
  create_additional_policy = (
    length(coalesce(var.workflow_config.role_statements, [])) > 0
  )
}


# WORKFLOW STATE MACHINE IAM ROLE -- BASIC SETUP
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    # Conditions to prevent the "confused deputy" security problem.
    # Note that each branch created for a parallel-type state generates a unique
    # execution ARN at runtime; thus, the "aws:SourceArn" conditional below must
    # have a star suffix to ensure those branches can still assume this role.
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:states:${local.current_region}:${local.current_account}:stateMachine:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

resource "aws_iam_role" "workflow_machine" {
  name_prefix        = "${var.resource_prefix}-workflow-role-"
  description        = "State Machine execution role for Cirrus Workflow '${var.workflow_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.workflow_machine_assume_role.json
}
# ==============================================================================


# WORKFLOW STATE MACHINE IAM ROLE -- EVENTS AND BATCH PERMISSIONS
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_basic_services" {

  statement {
    # Allow the state machine to push state transition events
    sid       = "AllowWorkflowToCreateStateTransitionEvents"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = ["*"]
  }

  # Batch only has partial support for resource-level permissions. See:
  # https://docs.aws.amazon.com/batch/latest/userguide/batch-supported-iam-actions-resources.html
  #
  # While "batch:TerminateJob" can be limited to specific Job ARNs, those ARNs
  # are not known until Job submission. That action does support conditional
  # policies via "aws:ResourceTag/Key", but there's no way to set Job tags via
  # Terraform; the Job Definition's "propagate_tags" field only passes tags to
  # the underlying ECS task and not the Batch Job itself. Thus, we cannot set
  # a resource restriction for that action, either.
  dynamic "statement" {
    for_each = local.create_batch_policy ? [1] : []

    content {
      sid    = "AllowWorkflowToManageTaskBatchJobs"
      effect = "Allow"
      actions = [
        "batch:DescribeJobs",
        "batch:TerminateJob"
      ]
      resources = ["*"]
    }
  }

  # Allow the state machine to monitor any Batch Jobs via the managed AWS rule
  dynamic "statement" {
    for_each = local.create_batch_policy ? [1] : []

    content {
      sid    = "AllowWorkflowToManageTaskBatchJobEvents"
      effect = "Allow"
      actions = [
        "events:PutTargets",
        "events:PutRule",
        "events:DescribeRule"
      ]
      resources = ["arn:aws:events:${local.current_region}:${local.current_account}:rule/StepFunctionsGetEventsForBatchJobsRule"]
    }
  }
}

resource "aws_iam_role_policy" "workflow_machine_basic_services" {
  name_prefix = "${var.resource_prefix}-workflow-role-basic-services-policy-"
  role        = aws_iam_role.workflow_machine.name
  policy      = data.aws_iam_policy_document.workflow_machine_basic_services.json
}

# WORKFLOW STATE MACHINE IAM ROLE -- EVENTS, BATCH, AND LAMBDA PERMISSIONS
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_basic_services_task_related" {

  statement {
    # Allow the state machine to push state transition events
    sid       = "AllowWorkflowToCreateStateTransitionEvents"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = ["*"]
  }

  # Allow the state machine to invoke any referenced task Lambdas
  dynamic "statement" {
    for_each = local.create_lambda_policy ? [1] : []

    content {
      sid       = "AllowWorkflowToInvokeTaskLambdaFunctions"
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = local.workflow_tasks_lambda_functions
    }
  }

  # Restrict Job submissions to the specified Job Definitions and Job Queues.
  # Those resources are determined by the user's template variables, so this
  # statement is nothing more than a simple guardrail against user error.
  dynamic "statement" {
    for_each = local.create_batch_policy ? [1] : []

    content {
      sid       = "AllowWorkflowToSubmitTaskBatchJobs"
      effect    = "Allow"
      actions   = ["batch:SubmitJob"]
      resources = local.workflow_tasks_batch_resources
    }
  }
}

resource "aws_iam_role_policy" "workflow_machine_basic_services_task_related" {
  name_prefix = "${var.resource_prefix}-workflow-role-basic-services-task-related-policy-"
  role        = aws_iam_role.workflow_machine.name
  policy      = data.aws_iam_policy_document.workflow_machine_basic_services_task_related.json
}
# ==============================================================================


# WORKFLOW STATE MACHINE IAM ROLE -- ADDITIONAL SERVICE PERMISSIONS
# ------------------------------------------------------------------------------
# Optionally creates an inline policy based on user input variables
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_additional_services" {
  count = local.create_additional_policy ? 1 : 0

  # Generate a statement block for each object in the input variable.
  # They are all added to this single policy document.
  dynamic "statement" {
    for_each = {
      for statement in var.workflow_config.role_statements :
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

resource "aws_iam_role_policy" "workflow_machine_additional_services" {
  count = local.create_additional_policy ? 1 : 0

  name_prefix = "${var.resource_prefix}-workflow-role-addtl-services-policy-"
  role        = aws_iam_role.workflow_machine.name
  policy      = data.aws_iam_policy_document.workflow_machine_additional_services[0].json
}
# ==============================================================================


# WORKFLOW STATE MACHINE
# ------------------------------------------------------------------------------
resource "aws_sfn_state_machine" "workflow" {
  name       = "${var.resource_prefix}-${var.workflow_config.name}"
  definition = local.workflow_state_machine_json
  publish    = true
  role_arn   = aws_iam_role.workflow_machine.arn
  type       = "STANDARD"
}
# ==============================================================================
