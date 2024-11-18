data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name

  # Create the template variable mapping.
  # Use each variable config as a lookup into the Cirrus Task outputs.
  template_variables = {
    for v_name, v_cfg in var.workflow_config.variables :
    v_name => var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
  }

  # Create the workflow's state machine JSON.
  # Use the template variable mapping above for interpolation.
  # Decode the rendered JSON to strip newlines then encode to minify.
  workflow_state_machine_json = jsonencode(jsondecode(templatefile(
    "${path.root}/${var.workflow_config.template}",
    local.template_variables
  )))

  # Gather any referenced Lambda Function ARNs.
  # These are needed for generating the workflow machine's IAM policies.
  # This includes both Cirrus- and non-Cirrus-managed Lambdas, if any.
  workflow_tasks_lambda_functions = concat(
    [
      for _, v_cfg in var.workflow_config.variables :
      var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
      if v_cfg.task_type == "lambda" && v_cfg.task_attr == "function_arn"
    ],
    try(coalesce(var.workflow_config.non_cirrus_lambda_arns, []), [])
  )

  # Gather any referenced Job Queue and Definition ARNs.
  # These are needed for generating the workflow machine's IAM policies.
  workflow_tasks_batch_resources = [
    for _, v_cfg in var.workflow_config.variables :
    var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
    if v_cfg.task_type == "batch" && (
      v_cfg.task_attr == "job_queue_arn" || v_cfg.task_attr == "job_definition_arn"
    )
  ]
}


# WORKFLOW STATE MACHINE IAM ROLE -- BASIC SETUP
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_assume_role_policy" {
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
      values   = ["${local.current_account}"]
    }
  }
}

resource "aws_iam_role" "workflow_machine" {
  name_prefix        = "${var.cirrus_prefix}-workflow-role-"
  description        = "State Machine execution role for Cirrus Workflow '${var.workflow_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.workflow_machine_assume_role_policy.json
}
# ==============================================================================


# WORKFLOW STATE MACHINE IAM ROLE -- LAMBDA PERMISSIONS
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_task_lambda_policy" {
  statement {
    # Allow the state machine to invoke all referenced task Lambdas
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = local.workflow_tasks_lambda_functions
  }
}

resource "aws_iam_role_policy" "workflow_machine_task_lambda_policy" {
  name_prefix = "${var.cirrus_prefix}-workflow-role-task-lambda-policy-"
  role        = aws_iam_role.workflow_machine.name
  policy      = data.aws_iam_policy_document.workflow_machine_task_lambda_policy.json
}
# ==============================================================================


# WORKFLOW STATE MACHINE IAM ROLE -- BATCH PERMISSIONS
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_task_batch_policy" {
  statement {
    # Batch only has partial support for resource-level permissions. See:
    # https://docs.aws.amazon.com/batch/latest/userguide/batch-supported-iam-actions-resources.html

    # While "batch:TerminateJob" can be limited to specific Job ARNs, those ARNs
    # are not known until Job submission. That action does support conditional
    # policies via "aws:ResourceTag/Key", but there's no way to set Job tags via
    # Terraform; the Job Definition's "propagate_tags" field only passes tags to
    # the underlying ECS task and not the Batch Job itself. Thus, we cannot set
    # a resource restriction for that action, either.
    effect = "Allow"
    actions = [
      "batch:DescribeJobs",
      "batch:TerminateJob"
    ]
    resources = ["*"]
  }

  statement {
    # Restrict Job submissions to the specified Job Definitions and Job Queues.
    # Those resources are determined by the user's input template variables, so
    # this statement is nothing more than a simple guardrail against user error.
    effect    = "Allow"
    actions   = ["batch:SubmitJob"]
    resources = local.workflow_tasks_batch_resources
  }

  statement {
    # Allow the state machine to monitor Batch Jobs via the managed AWS rule
    effect = "Allow"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule"
    ]
    resources = ["arn:aws:events:${local.current_region}:${local.current_account}:rule/StepFunctionsGetEventsForBatchJobsRule"]
  }
}

resource "aws_iam_role_policy" "workflow_machine_task_batch_policy" {
  name_prefix = "${var.cirrus_prefix}-workflow-role-task-batch-policy-"
  role        = aws_iam_role.workflow_machine.name
  policy      = data.aws_iam_policy_document.workflow_machine_task_batch_policy.json
}
# ==============================================================================


# WORKFLOW STATE MACHINE
# ------------------------------------------------------------------------------
resource "aws_sfn_state_machine" "workflow_machine" {
  name       = "${var.cirrus_prefix}-${var.workflow_config.name}"
  definition = local.workflow_state_machine_json
  publish    = true
  role_arn   = aws_iam_role.workflow_machine.arn
  type       = "STANDARD"
}
# ==============================================================================
