variable "resource_prefix" {
  description = "String prefix to be used in every named resource."
  type        = string
  nullable    = false
}

variable "feeder_config" {
  # NOTE: type changes here require changes in the typed-definitions module, too
  type = object({
    name        = string
    description = optional(string)

    lambda = object({
      filename = optional(string)
      handler  = optional(string)
      runtime  = optional(string)
    })

    sqs = optional(object({
      message_retention_seconds = optional(number)
    }))
  })

  # Value must be provided else this module serves no purpose
  nullable = false

  validation {
    condition     = var.feeder_config.lambda != null
    error_message = "Feeder configs must specify a Lambda config"
  }
}
