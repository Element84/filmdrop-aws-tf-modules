variable "resource_prefix" {
  description = "String prefix to be used in every named resource."
  type        = string
  nullable    = false
}

# TODO: description
variable "feeder_config" {
  description = <<-DESCRIPTION
  Defines the core Cirrus feeder infrastructure.

  `name`: (Required) Identifier for the cirrus feeder. Must be unique across all feeders. Valid characters are: `[A-Za-z0-9-]`.

  `triggers_sns`: (Optional) List of SNS topic(s) to subscribe the feeder to. Each entry must include the `topic_arn` and may optionally include `delivery_policy`, `filter_policy`, `filter_policy_scope`, and `raw_message_delivery`. See Terraform's [aws_sns_topic_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) resource documentation for details.

  `triggers_s3`: (Optional) List of S3 bucket(s) to configure event notifications on. Each entry must include the `bucket_name`, `bucket_arn`, and `events` attributes, and may optionally include `filter_prefix` and `filter_suffix`. See Terraform's [aws_s3_bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) resource documentation for details.

  `sqs`: (Optional) Configuration for the feeder's SQS queue. If not provided, defaults will be used. See Terraform's [aws_sqs_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) resource documentation for details.

  `lambda`: The standard config for Cirrus Task and Feeder Lambdas. See the /cirrus/task/README.md for full details.
  DESCRIPTION

  # NOTE: type changes here require changes in the typed-definitions module, too
  type = object({
    name = string

    triggers_sns = optional(list(object({
      topic_arn            = string
      delivery_policy      = optional(string)
      filter_policy        = optional(string)
      filter_policy_scope  = optional(string)
      raw_message_delivery = optional(bool)
    })))

    triggers_s3 = optional(list(object({
      bucket_name   = string
      bucket_arn    = string
      events        = list(string)
      filter_prefix = optional(string)
      filter_suffix = optional(string)
    })))

    sqs = optional(object({
      delay_seconds              = optional(number)
      max_message_size           = optional(number)
      message_retention_seconds  = optional(number)
      receive_wait_time_seconds  = optional(number)
      visibility_timeout_seconds = optional(number)
      max_receive_count          = optional(number)
    }))

    lambda = optional(object({
      description               = optional(string)
      ecr_image_uri             = optional(string)
      resolve_ecr_tag_to_digest = optional(bool)
      filename                  = optional(string)
      image_config = optional(object({
        command           = optional(list(string))
        entry_point       = optional(list(string))
        working_directory = optional(string)
      }))
      s3_bucket       = optional(string)
      s3_key          = optional(string)
      handler         = optional(string)
      runtime         = optional(string)
      timeout_seconds = optional(number)
      memory_mb       = optional(number)
      publish         = optional(bool)
      architectures   = optional(list(string))
      env_vars        = optional(map(string))
      vpc_enabled     = optional(bool)
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
    }))
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  })
  # The `~~~~` comment above is to ensure the markdown table column generated
  # by terraform-docs is wide enough for the object schema to be readable.

  # Value must be provided else this module serves no purpose
  nullable = false

  validation {
    condition     = var.feeder_config.lambda != null
    error_message = "Feeder configs must specify a Lambda config"
  }
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

variable "warning_sns_topic_arn" {
  description = <<-DESCRIPTION
  SNS topic to be used by all `warning` alarms.

  If any non-critical alarms are configured via `var.feeder_config.lambda.alarms`, they will use this SNS topic for their alarm action.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "critical_sns_topic_arn" {
  description = <<-DESCRIPTION
  SNS topic to be used by all `critical` alarms.

  If any critical alarms are configured via `var.feeder_config.lambda.alarms`, they will use this SNS topic for their alarm action.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "builtin_feeder_definitions_variables" {
  description = <<-DESCRIPTION
  Predefined builtin variables, such as `CIRRUS_DATA_BUCKET`, that are set in the `cirrus` module.
  DESCRIPTION
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "cirrus_process_sqs_queue_url" {
  description = <<-DESCRIPTION
  URL of the cirrus process queue. Given that feeders' primary function is to enqueue messages to the process queue this is required. 
  DESCRIPTION
  type        = string
}
