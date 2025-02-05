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
  # NOTE: type changes here require changes in the typed-definitions module, too
  description = <<-DESCRIPTION
    (required, object) Defines a single Cirrus Workflow.
    Contents:
      - name: (required, string) Identifier for the Cirrus Workflow. Must be
        unique across all Cirrus Workflows. Valid characters are: [A-Za-z0-9-]

      - state_machine_filepath: (required, string) Path to an Amazon State
        Machine definition template file. The path must be relative to the ROOT
        module of the Terraform deployment. The template should use valid Amazon
        States Language syntax; wherever a Cirrus Task resource ARN is needed, a
        Terraform interpolation sequence (a "$\{...}" without the "\") may be
        used instead. The interpolation sequence should have the following form:
          <TASK NAME>.<TASK TYPE>.<TASK ATTR>

        Where:
          <TASK NAME> : name of the task
          <TASK TYPE> : one of [lambda, batch]
          <TASK ATTR> : one of [function_arn, job_definition_arn, job_queue_arn]

        Example template snippet:
          "States": {
            "FirstState": {
              "Type": "Task",
              "Resource": "$\{my-task.lambda.function_arn}",  // REMOVE THE "\"
              "Next": "SecondState",
              ...
            },
  DESCRIPTION

  type = object({
    name                   = string
    state_machine_filepath = string
  })

  # Value must be provided else this module serves no purpose
  nullable = false
}
