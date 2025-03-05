data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name

  # Create the workflow's state machine JSON.
  # Use the Cirrus task output mapping for interpolation.
  # Decode the rendered JSON to strip newlines then encode to minify.
  workflow_state_machine_json = jsonencode(jsondecode(templatefile(
    "${path.root}/${var.workflow_config.state_machine_filepath}",
    var.cirrus_tasks
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
  name_prefix        = "${var.cirrus_prefix}-workflow-role-"
  description        = "State Machine execution role for Cirrus Workflow '${var.workflow_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.workflow_machine_assume_role.json
}

data "aws_iam_policy_document" "workflow_machine_events" {
  statement {
    # Allow the state machine to push state transition events
    sid       = "AllowWorkflowToCreateStateTransitionEvents"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "workflow_machine_events" {
  name_prefix = "${var.cirrus_prefix}-workflow-role-event-creation-"
  role        = aws_iam_role.workflow_machine.name
  policy      = data.aws_iam_policy_document.workflow_machine_events.json
}
# ==============================================================================


# WORKFLOW STATE MACHINE IAM ROLE -- BATCH AND LAMBDA PERMISSIONS
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_task_lambda_and_batch" {

  # TODO - CVG - hardcoded to allow all SQS queues for now
  statement {
    sid       = "AllowWorkflowToUseSqsCallbackEvents"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:${local.current_region}:${local.current_account}:*"]
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

resource "aws_iam_role_policy" "workflow_machine_task_lambda_and_batch" {
  name_prefix = "${var.cirrus_prefix}-workflow-role-task-policy-"
  role        = aws_iam_role.workflow_machine.name
  policy      = data.aws_iam_policy_document.workflow_machine_task_lambda_and_batch.json
}
# ==============================================================================


# WORKFLOW STATE MACHINE IAM ROLE -- ADDITIONAL PERMISSIONS
# ------------------------------------------------------------------------------
# TODO - CVG - hardcoded to allow all SQS queues for now
# data "aws_iam_policy_document" "workflow_machine_additional" {
#   statement {
#     sid       = "AllowWorkflowToUseSqsCallbackEvents"
#     effect    = "Allow"
#     actions   = ["sqs:SendMessage"]
#     resources = ["arn:aws:sqs:${local.current_region}:${local.current_account}:*"]
#   }
# }
#
# resource "aws_iam_role_policy" "workflow_machine_additional" {
#   name_prefix = "${var.cirrus_prefix}-workflow-role-additional-"
#   role        = aws_iam_role.workflow_machine.name
#   policy      = data.aws_iam_policy_document.workflow_machine_additional.json
# }
# ==============================================================================


# WORKFLOW STATE MACHINE
# ------------------------------------------------------------------------------
resource "aws_sfn_state_machine" "workflow" {
  name       = "${var.cirrus_prefix}-${var.workflow_config.name}"
  definition = local.workflow_state_machine_json
  publish    = true
  role_arn   = aws_iam_role.workflow_machine.arn
  type       = "STANDARD"
}
# ==============================================================================
