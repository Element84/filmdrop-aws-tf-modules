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

      - default_template_config: (optional, object) Used to create an Amazon
        State Machine by rendering and combining predefined state configurations
        using outputs from the Cirrus Tasks referenced in 'state_sequence'. If
        your State Machine is a simple sequential execution of Cirrus Tasks,
        this config should be preferred over 'custom_template_config' as it
        removes the need for creating a State Machine definition template.
        Contents:
          - description: (required, string) Workflow description
          - allow_retry: (required, bool) Whether individual states should be
            retried in the event of a failure.
          - state_sequence: (required, list[object]) List of Cirrus Tasks that
            will be executed sequentially.
            Contents:
              - task_name: (required, string) Cirrus Task name. Used for getting
                Task output resource ARNs. Will also be used for the state name
                if 'state_name' is omitted.
              - task_type: (required, string) lambda or batch
              - state_name: (optional, string) State name. Must be unique within
                the Workflow. In most cases, this can be omitted as 'task_name'
                is used by default. Useful if you need to call the same Task
                multiple times within a Workflow.

      - custom_template_config: (optional, object) Used to create an Amazon
        State Machine by rendering a user-provided template with variables that
        reference Cirrus Task outputs. Useful for complex State Machines that
        cannot be created using the 'default_template_config' option.
        Contents:
          - filepath: (required, string) Path to an Amazon State Machine
            template definition. The path must be relative to the ROOT module of
            the Terraform deployment. The template should use valid Amazon State
            Language syntax; wherever a Cirrus Task resource ARN is needed, a
            Terraform interpolation sequence (a "$\{...}" without the "\") may
            be used instead. The variable name does not matter so long as there
            is a corresponding entry in the "template_variables" argument.
            Example template snippet:

              "States": {
                "FirstState": {
                  "Type": "Task",
                  "Resource": "$\{my-task-lambda}",  // REMOVE THE "\"
                  "Next": "SecondState",
                  ...
                },

            Cirrus may deploy and manage several builtin tasks. Resource ARNs
            for these tasks may be referenced in a Workflow template using
            predefined variable names without having to supply a
            'template_variable' entry.
              - If Batch Tasks were created, these variables may be used:
                - PRE-BATCH: cirrus-geo pre-batch Lambda function ARN
                - POST-BATCH: cirrus-geo post-batch Lambda function ARN

          - template_variables: (optional, map[object]) Map of template variable
            names to their corresponding Cirrus Task attributes. Assuming a
            Cirrus Task named "my-task" with a Lambda config was passed to the
            'task' module, the following workflow template variable config:

              my-task-lambda = {
                task_name = "my-task"
                task_type = "lambda"
                task_attr = "function_arn"
              }

            when used with the example Workflow snippet above, would result in
            the following content after template interpolation:

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
    default_template_config = optional(object({
      description = string
      allow_retry = bool
      state_sequence = list(object({
        state_name = optional(string)
        task_name  = string
        task_type  = string
      }))
    }))
    custom_template_config = optional(object({
      filepath = string
      variables = optional(map(object({
        task_name = string
        task_type = string
        task_attr = string
      })))
    }))
  })

  # Value must be provided else this module serves no purpose
  nullable = false

  validation {
    condition = (
      try(var.workflow_config.custom_template_config.variables, null) != null
      ? alltrue([
        for _, tpl_variable in var.workflow_config.custom_template_config.variables :
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
      Invalid variable config provided. Each key must have a valid value:
        - task_type => one of ["lambda", "batch"]
        - task_attr => one of ["function_arn", "job_definition_arn", "job_queue_arn"]
    ERROR
  }

  validation {
    condition = (
      var.workflow_config.default_template_config != null
      ? length(distinct([
        for state in var.workflow_config.default_template_config.state_sequence :
        coalesce(state.state_name, state.task_name)
      ])) == length(var.workflow_config.default_template_config.state_sequence)
      : true
    )
    error_message = <<-ERROR
      Invalid state sequence provided. Each state must have a unique name (the
      'task_name' attribute is used if 'state_name' was not provided). Set the
      'state_name' attribute on states as needed to avoid name collisions.
    ERROR
  }

  validation {
    condition = (
      var.workflow_config.default_template_config != null
      ? alltrue([
        for state in var.workflow_config.default_template_config.state_sequence :
        contains(["lambda", "batch"], state.task_type)
      ])
      : true
    )
    error_message = <<-ERROR
      Invalid state sequence provided. Each key must have a valid value:
        - task_type => one of ["lambda", "batch"]
    ERROR
  }

  validation {
    condition = (
      (
        var.workflow_config.default_template_config == null
        && var.workflow_config.custom_template_config != null
      )
      ||
      (
        var.workflow_config.default_template_config != null
        && var.workflow_config.custom_template_config == null
      )
    )
    error_message = <<-ERROR
      Invalid workflow config provided. Exactly one of 'default_template_config'
      and 'custom_template_config' must be set.
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
