variable "cirrus_prefix" {
  description = "Prefix for Cirrus-managed resources"
  type        = string
}

variable "cirrus_tasks" {
  description = "Optional output from the Cirrus Terraform tasks module"
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
  description = "Configuration object defining a single Cirrus Workflow"
  type = object({
    name                   = string
    template               = string
    additional_lambda_arns = optional(list(string))
    # Each map key here must be a key in the 'cirrus_tasks' map above
    variables = optional(map(object({
      task_name = string
      task_type = string
      task_attr = string
    })))
  })

  # Value must be provided else this module serves no purpose
  nullable = false
}