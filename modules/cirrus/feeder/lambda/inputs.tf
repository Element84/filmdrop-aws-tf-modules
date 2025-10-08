variable "function_name" {
  description = "Lambda function name. Auxillary resources will be prefixed with this."
  type        = string
  nullable    = false
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the target VPC that cirrus the lambda resources should be connected to."
  type        = list(string)
  nullable    = false
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the target VPC that cirrus the lambda resources should use."
  type        = list(string)
  nullable    = false
}

variable "lambda_config" {
  type = object({
    description               = optional(string)
    ecr_image_uri             = optional(string)
    resolve_ecr_tag_to_digest = optional(bool)
    filename                  = optional(string)
    image_config = optional(object({
      command           = optional(list(string))
      entry_point       = optional(list(string))
      working_directory = optional(string)
    }))
    s3_bucket            = optional(string)
    s3_key               = optional(string)
    handler              = optional(string)
    runtime              = optional(string)
    timeout_seconds      = optional(number)
    memory_mb            = optional(number)
    ephemeral_storage_mb = optional(number)
    publish              = optional(bool)
    architectures        = optional(list(string))
    env_vars             = optional(map(string))
    vpc_enabled          = optional(bool)
    role_statements = optional(list(object({
      sid           = string
      effect        = string
      actions       = list(string)
      resources     = list(string)
      not_actions   = optional(list(string))
      not_resources = optional(list(string))
      condition = optional(object({
        test     = string
        variable = string
        values   = list(string)
      }))
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      not_principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
    })))
    alarms = optional(list(object({
      critical            = bool
      statistic           = string
      metric_name         = string
      comparison_operator = string
      threshold           = number
      period              = optional(number, 60)
      evaluation_periods  = optional(number, 5)
    })))
  })
}

variable "warning_sns_topic_arn" {
  description = <<-DESCRIPTION
  (Optional) SNS topic to be used by all `warning` alarms.

  If any non-critical alarms are configured via `var.lambda_config.alarms`, they will use this SNS topic for their alarm action.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "critical_sns_topic_arn" {
  description = <<-DESCRIPTION
  (Optional) SNS topic to be used by all `critical` alarms.

  If any critical alarms are configured via `var.lambda_config.alarms`, they will use this SNS topic for their alarm action.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}
