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

    triggers_sns = optional(list(object({
      topic_name_suffix    = string
      delivery_policy      = optional(string)
      filter_policy        = optional(string)
      filter_policy_scope  = optional(string)
      raw_message_delivery = optional(bool)
    })))

    triggers_s3 = optional(list(object({
      bucket_name_suffix = string
      events             = list(string)
      filter_prefix      = optional(string)
      filter_suffix      = optional(string)
    })))

    sqs = optional(object({
      delay_seconds              = optional(number)
      max_message_size           = optional(number)
      message_retention_seconds  = optional(number)
      receive_wait_time_seconds  = optional(number)
      visibility_timeout_seconds = optional(number)
      max_receive_count          = optional(number)
    }))

    lambda = object({
      filename = optional(string)
      handler  = optional(string)
      runtime  = optional(string)
    })
  })

  # Value must be provided else this module serves no purpose
  nullable = false

  validation {
    condition     = var.feeder_config.lambda != null
    error_message = "Feeder configs must specify a Lambda config"
  }
}
