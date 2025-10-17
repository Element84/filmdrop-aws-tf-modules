variable "function_name" {
  description = "Lambda function name. Auxillary resources will be prefixed with this."
  type        = string
  nullable    = false
}

variable "vpc_subnet_ids" {
  description = <<-DESCRIPTION
  List of subnet ids in the target VPC that the lambda resources should be connected to.
  DESCRIPTION
  type        = list(string)
  nullable    = false
}

variable "vpc_security_group_ids" {
  description = <<-DESCRIPTION
  List of security groups in the target VPC that the lambda resources should use.
  DESCRIPTION
  type        = list(string)
  nullable    = false
}

variable "lambda_config" {
  description = <<-DESCRIPTION
  The standard config for Cirrus Task and Feeder Lambdas. See the /cirrus/task/README.md for full details.

  Note: if possible, reusing this module for both tasks and feeders may be beneficial, moving the documentation of the lambda_config here centrally.
  DESCRIPTION

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

variable "lambda_env_vars" {
  description = <<-DESCRIPTION
  Map of environment variables to set in the lambda function. Note that lambda_config.env_vars allows for a map of environment variables to be set as well; if both are provided, the maps will be merged. lambda_config.env_vars is intended for user-provided environment variables via the definition.yaml config). This variable is intended for environment variables that are required for the lambda to function properly, and thus are set at the module level.

  DESCRIPTION
  type        = map(string)
  nullable    = true
  default     = null
}

variable "warning_sns_topic_arn" {
  description = <<-DESCRIPTION
  SNS topic to be used by all `warning` alarms.

  If any non-critical alarms are configured via `var.lambda_config.alarms`, they will use this SNS topic for their alarm action.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "critical_sns_topic_arn" {
  description = <<-DESCRIPTION
  SNS topic to be used by all `critical` alarms.

  If any critical alarms are configured via `var.lambda_config.alarms`, they will use this SNS topic for their alarm action.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}
