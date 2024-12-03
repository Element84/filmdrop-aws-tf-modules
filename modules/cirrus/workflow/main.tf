data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name

  # Whether to construct a simple state machine definition or render the user's
  use_default_template = try(var.workflow_config.default_template_config, null) != null

  # Default Template - Each state must have a name.
  # If one was not explicitly provided, use the task name instead.
  default_template_states = (
    local.use_default_template
    ? [
      for s_cfg in var.workflow_config.default_template_config.state_sequence :
      merge(s_cfg, { state_name = coalesce(s_cfg.state_name, s_cfg.task_name) })
    ]
    : []
  )

  # Default Template - Construct state contents using the Lambda/Batch template.
  # The merged template variables map consists of:
  #  - State configuration variables
  #  - Builtin variables and their associated Cirrus Task resource ARNs
  #  - Outputs from the state's associated Cirrus Task
  default_template_state_strings = (
    local.use_default_template
    ? [
      for idx, s_cfg in local.default_template_states :
      templatefile(
        "${path.module}/templates/${s_cfg.task_type}_state.tftpl",
        merge(
          {
            state_name  = s_cfg.state_name
            allow_retry = var.workflow_config.default_template_config.allow_retry
            next_or_end = (
              idx != (length(local.default_template_states) - 1)
              ? local.default_template_states[idx + 1].state_name
              : null
            )
          },
          {
            for v, v_cfg in var.builtin_task_template_variables :
            v => var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
          },
          var.cirrus_tasks[s_cfg.task_name][s_cfg.task_type]
        )
      )
    ]
    : []
  )

  # Custom Template - Merge builtin template variables with user-defined ones
  merged_workflow_template_variables = (
    local.use_default_template
    ? null
    : merge(
      var.builtin_task_template_variables,
      coalesce(var.workflow_config.custom_template_config.variables, tomap({}))
    )
  )

  # Default or Custom Template - Gather referenced Lambda Function ARNs.
  # These are needed for generating the workflow machine's IAM policies.
  # This includes both Cirrus- and non-Cirrus-managed Lambdas, if any.
  workflow_tasks_lambda_functions = (
    local.use_default_template
    # Get Lambda resource ARNs from state configs and builtin variables
    ? concat(
      [
        for state_cfg in local.default_template_states :
        var.cirrus_tasks[state_cfg.task_name][state_cfg.task_type]["function_arn"]
        if state_cfg.task_type == "lambda"
      ],
      [
        for _, v_cfg in var.builtin_task_template_variables :
        var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
        if v_cfg.task_type == "lambda" && v_cfg.task_attr == "function_arn"
      ],
      try(coalesce(var.workflow_config.non_cirrus_lambda_arns, []), [])
    )
    # Get Lambda resource ARNs from the merged user and builtin variables
    : concat(
      [
        for _, v_cfg in local.merged_workflow_template_variables :
        var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
        if v_cfg.task_type == "lambda" && v_cfg.task_attr == "function_arn"
      ],
      try(coalesce(var.workflow_config.non_cirrus_lambda_arns, []), [])
    )
  )

  # Default or Custom Template - Gather referenced Job Queue/Definition ARNs.
  # These are needed for generating the workflow machine's IAM policies.
  workflow_tasks_batch_resources = (
    local.use_default_template
    # Get Batch resource ARNs from state configs and builtin variables
    ? concat(
      flatten([
        for s_cfg in local.default_template_states :
        s_cfg.task_type == "batch"
        ? [
          var.cirrus_tasks[s_cfg.task_name][s_cfg.task_type]["job_definition_arn"],
          var.cirrus_tasks[s_cfg.task_name][s_cfg.task_type]["job_queue_arn"]
        ]
        : []
      ]),
      [
        for _, v_cfg in var.builtin_task_template_variables :
        var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
        if v_cfg.task_type == "batch" && (
          v_cfg.task_attr == "job_queue_arn" || v_cfg.task_attr == "job_definition_arn"
        )
      ]
    )
    # Get Batch resource ARNs from the merged user and builtin variables
    : [
      for _, v_cfg in local.merged_workflow_template_variables :
      var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
      if v_cfg.task_type == "batch" && (
        v_cfg.task_attr == "job_queue_arn" || v_cfg.task_attr == "job_definition_arn"
      )
    ]
  )

  # Default & Custom Template - Create the workflow's state machine JSON.
  # Decode to strip newlines and then encode to minify.
  workflow_state_machine_json = (
    local.use_default_template
    # Render the default template using contents of all rendered state objects
    ? jsonencode(jsondecode(templatefile(
      "${path.module}/templates/default.tftpl",
      {
        workflow_description = var.workflow_config.default_template_config.description
        first_state_name     = local.default_template_states[0].state_name
        state_strings        = local.default_template_state_strings
      }
    )))
    # Render the user-provided template using the variable mapping to replace
    # interpolation sequences with their desired resource ARNs
    : jsonencode(jsondecode(templatefile(
      "${path.root}/${var.workflow_config.custom_template_config.filepath}",
      {
        for v_name, v_cfg in local.merged_workflow_template_variables :
        v_name => var.cirrus_tasks[v_cfg.task_name][v_cfg.task_type][v_cfg.task_attr]
      }
    )))
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
# ==============================================================================


# WORKFLOW STATE MACHINE IAM ROLE -- LAMBDA PERMISSIONS
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_task_lambda" {
  count = local.create_lambda_policy ? 1 : 0

  statement {
    # Allow the state machine to invoke all referenced task Lambdas
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = local.workflow_tasks_lambda_functions
  }
}

resource "aws_iam_role_policy" "workflow_machine_task_lambda" {
  count = local.create_lambda_policy ? 1 : 0

  name_prefix = "${var.cirrus_prefix}-workflow-role-task-lambda-policy-"
  role        = aws_iam_role.workflow_machine.name
  policy      = data.aws_iam_policy_document.workflow_machine_task_lambda[0].json
}
# ==============================================================================


# WORKFLOW STATE MACHINE IAM ROLE -- BATCH PERMISSIONS
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "workflow_machine_task_batch" {
  count = local.create_batch_policy ? 1 : 0

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

resource "aws_iam_role_policy" "workflow_machine_task_batch" {
  count = local.create_batch_policy ? 1 : 0

  name_prefix = "${var.cirrus_prefix}-workflow-role-task-batch-policy-"
  role        = aws_iam_role.workflow_machine.name
  policy      = data.aws_iam_policy_document.workflow_machine_task_batch[0].json
}
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
