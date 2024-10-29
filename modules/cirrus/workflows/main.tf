locals {
  # TODO - CVG - use validation block in the variable instead
  # Reformat the workflow name for consistency
  workflow_name = lower(replace(var.workflow_config.name, "/[\\._\\s]/", "-"))

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

  # TODO - CVG - Additional task lambdas based on user input here?
  workflow_tasks_lambda_functions = [
    for _, v_cfg in var.workflow_config.variables :
    var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
    if v_cfg.task_type == "lambda" && v_cfg.task_attr == "arn"
  ]

  # TODO - CVG - add onoce batch tasks are configured
  # workflow_tasks_batch_job_tags = []
  # workflow_tasks_batch_job_queues = []
  # workflow_tasks_batch_job_definitions = []
}


# WORKFLOW STATE MACHINE IAM ROLE - BASIC SETUP
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.cirrus_prefix}-${local.workflow_name}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}

resource "aws_iam_role" "workflow_machine" {
  name_prefix        = "${var.cirrus_prefix}-workflow-role-"
  description        = "State Machine execution role for Cirrus Workflow '${local.workflow_name}'"
  assume_role_policy = data.aws_iam_policy_document.workflow_machine_assume_role_policy.json
}
# ==============================================================================


# WORKFLOW STATE MACHINE IAM ROLE - LAMBDA PERMISSIONS
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_task_lambda_policy" {
  statement {
    sid       = "AllowWorkflowStateMachineToInvokeCirrusTaskLambdas"
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


# WORKFLOW STATE MACHINE IAM ROLE - BATCH PERMISSIONS
# ------------------------------------------------------------------------------
# TODO - CVG - add onoce batch tasks are configured
# ==============================================================================


# WORKFLOW STATE MACHINE
# ------------------------------------------------------------------------------
resource "aws_sfn_state_machine" "workflow_machine" {
  name       = "${var.cirrus_prefix}-${local.workflow_name}"
  type       = "STANDARD"
  role_arn   = aws_iam_role.workflow_machine.arn
  definition = local.workflow_state_machine_json
  publish    = true
}
# ==============================================================================

