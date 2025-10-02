variable "resource_prefix" {
  description = "String prefix to be used in every named resource."
  type        = string
  nullable    = false
}

variable "feeder_config" {
  # NOTE: type changes here require changes in the typed-definitions module, too
  type = list(object({
    name = string

    sqs = object({
      message_retention_seconds = optional(number)
    })

    lambda = object({
      filename = optional(string)
    })
  }))

  # Value must be provided else this module serves no purpose
  nullable = false

  validation {
    condition     = var.feeder_config.lambda != null
    error_message = "Feeder configs must specify Lambda config"
  }
  validation {
    condition     = var.feeder_config.sqs != null
    error_message = "Feeder configs must specify SQS config"
  }
}
