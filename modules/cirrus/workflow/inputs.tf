variable "cirrus_prefix" {
  description = "Prefix for Cirrus-managed resources"
  type        = string
}

variable "cirrus_tasks" {
  description = <<-DESCRIPTION
  (optional, map[object]) A map of the 'task' module outputs. These are used for
  variable interpolation in the Workflow state machine definition template. This
  should be set in the parent module and not by user input.
  DESCRIPTION

  type = map(object({
    lambda = object({
      function_arn = optional(string)
    })
    batch = object({
      job_queue_arn      = optional(string)
      job_definition_arn = optional(string)
    })
  }))

  # Tasks aren't technically needed if the user's workflow JSON template doesn't
  # reference any variables, though this is unlikely.
  nullable = true
}

variable "workflow_config" {
  description = <<-DESCRIPTION
    (required, object) Defines a single Cirrus Workflow.
    Contents:
      - name: (required, string) Identifier for the Cirrus Workflow. Must be
        unique across all Cirrus Workflows. Valid characters are: [A-Za-z0-9-]

      - non_cirrus_lambda_arns: (optional, list[string]) List of Lambda function
        ARNs that'll be executed by the Workflow but are not managed by a Cirrus
        task. This is necessary for granting the Workflow execution role invoke
        permissions on these functions.

      - template_filepath: (required, string) Path to an Amazon State Machine
        definition template file. The path must be relative to the ROOT module
        of the Terraform deployment. The template should use valid Amazon States
        Language syntax; wherever a Cirrus Task resource ARN is needed, a
        Terraform interpolation sequence (a "$\{...}" without the "\") may be
        used instead. The variable name does not matter so long as there is a
        corresponding entry in the "template_variables" argument.
        Example template snippet:

          "States": {
            "FirstState": {
              "Type": "Task",
              "Resource": "$\{my-task-lambda}",  // REMOVE THE "\"
              "Next": "SecondState",
              ...
            },

        Cirrus may deploy and manage several builtin tasks. Resource ARNs for
        these tasks may be referenced in a Workflow template using a predefined
        variable name without having to supply a 'template_variable' entry.
          - If Batch Tasks were created, the following variables may be used:
            - PRE-BATCH: cirrus-geo pre-batch Lambda function ARN
            - POST-BATCH: cirrus-geo post-batch Lambda function ARN

      - template_variables: (optional, map[object]) A map of template variable
        names to their corresponding Cirrus Task attributes. Assuming a Cirrus
        Task named "my-task" with Lambda config was passed to the 'task' module,
        the following workflow template variable config:

          my-task-lambda = {
            task_name = "my-task"
            task_type = "lambda"
            task_attr = "function_arn"
          }

        when used with the example Workflow snippet above would result in the
        following content after template interpolation:

          "States": {
            "FirstState": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:us-west-2:123456789012:function:my-function",
              "Next": "SecondState",
              ...
            },
  DESCRIPTION

  type = object({
    name                   = string
    non_cirrus_lambda_arns = optional(list(string))
    template_filepath      = string
    template_variables = optional(map(object({
      task_name = string
      task_type = string
      task_attr = string
    })))
  })

  # Value must be provided else this module serves no purpose
  nullable = false

  validation {
    condition = (
      var.workflow_config.template_variables != null
      ? alltrue([
        for _, tpl_variable in var.workflow_config.template_variables :
        (
          contains(
            ["lambda", "batch"],
            tpl_variable.task_type
          )
          && contains(
            ["function_arn", "job_definition_arn", "job_queue_arn"],
            tpl_variable.task_attr
          )
        )
      ])
      : true
    )

    error_message = <<-ERROR
      Invalid template variable config. Each key must have a valid value:
        - task_type => one of ["lambda", "batch"]
        - task_attr => one of ["function_arn", "job_definition_arn", "job_queue_arn"]
    ERROR
  }
}

variable "builtin_task_template_variables" {
  description = <<-DESCRIPTION
    (optional, object) Key/value pairs of builtin task variables used during
    workflow state machine templating. This should be set in the parent module
    and not by user input.
  DESCRIPTION

  type = map(object({
    task_name = string
    task_type = string
    task_attr = string
  }))

  # Value should always be a map (empty map is OK)
  default  = {}
  nullable = false
}
