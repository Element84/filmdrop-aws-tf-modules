variable "cirrus_prefix" {
  description = "Prefix for Cirrus-managed resources"
  type        = string
}

variable "cirrus_tasks" {
  description = "The Cirrus Task Terraform module output which describes created Cirrus Tasks"
  type = map(object({
    lambda = object({
      arn = optional(string)
    })
  }))
}

variable "workflow_config" {
  description = "Configuration block defining a single Cirrus Workflow"
  type = object({
    name     = string
    template = string
    variables = optional(map(object({
      task_name = string
      task_type = string
      task_attr = string
    })))
  })
}