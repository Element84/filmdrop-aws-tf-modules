variable "environment" {
  description = "Project environment."
  type        = string
  validation {
    condition     = length(var.environment) <= 7
    error_message = "The environment value must be 7 or fewer characters."
  }
}

variable "project_name" {
  description = "Project Name"
  type        = string
  validation {
    condition     = length(var.project_name) <= 8
    error_message = "The project_name value must be a 8 or fewer characters."
  }
}

variable "vpc_id" {
  description = "FilmDrop VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "security_group_id" {
  description = "Default security groups in the FilmDrop vpc"
  type        = string
}

variable "cirrus_inputs" {
  description = "Inputs for FilmDrop Cirrus deployment"
  type = object({
    data_bucket                               = string
    payload_bucket                            = string
    log_level                                 = string
    api_rest_type                             = string
    private_api_additional_security_group_ids = optional(list(string))
    deploy_alarms                             = bool
    private_certificate_arn                   = optional(string)
    domain_alias                              = optional(string)
    custom_alarms = object({
      warning  = map(any)
      critical = map(any)
    })
    process = object({
      sqs_timeout                   = number
      sqs_max_receive_count         = number
      sqs_cross_account_sender_arns = optional(list(string))
    })
    state = object({
      timestream_magnetic_store_retention_period_in_days = number
      timestream_memory_store_retention_period_in_hours  = number
    })
    lambda_version      = optional(string)
    lambda_zip_filepath = optional(string)
    api_lambda = object({
      timeout = number
      memory  = number
    })
    process_lambda = object({
      timeout              = number
      memory               = number
      reserved_concurrency = number
    })
    update_state_lambda = object({
      timeout = number
      memory  = number
    })
    pre_batch_lambda = object({
      timeout = number
      memory  = number
    })
    post_batch_lambda = object({
      timeout = number
      memory  = number
    })
    task_batch_compute_definitions_dir           = optional(string)
    task_batch_compute_definitions_variables     = optional(map(map(string)))
    task_batch_compute_definitions_variables_ssm = optional(map(map(string)))
    task_definitions_dir                         = optional(string)
    task_definitions_variables                   = optional(map(map(string)))
    task_definitions_variables_ssm               = optional(map(map(string)))
    workflow_definitions_dir                     = optional(string)
    workflow_definitions_variables               = optional(map(map(string)))
    workflow_definitions_variables_ssm           = optional(map(map(string)))
    cirrus_cli_iam_role_trust_principal          = optional(list(string))
  })
  default = {
    data_bucket                               = "cirrus-data-bucket-name"
    payload_bucket                            = "cirrus-payload-bucket-name"
    log_level                                 = "INFO"
    api_rest_type                             = "EDGE"
    private_api_additional_security_group_ids = null
    deploy_alarms                             = true
    private_certificate_arn                   = ""
    domain_alias                              = ""
    custom_alarms = {
      warning  = {}
      critical = {}
    }
    process = {
      sqs_timeout                   = 180
      sqs_max_receive_count         = 5
      sqs_cross_account_sender_arns = []
    }
    state = {
      timestream_magnetic_store_retention_period_in_days = 93
      timestream_memory_store_retention_period_in_hours  = 24
    }
    lambda_version      = null
    lambda_zip_filepath = null
    api_lambda = {
      timeout = 10
      memory  = 128
    }
    process_lambda = {
      timeout              = 10
      memory               = 128
      reserved_concurrency = 16
    }
    update_state_lambda = {
      timeout = 15
      memory  = 128
    }
    pre_batch_lambda = {
      timeout = 15
      memory  = 128
    }
    post_batch_lambda = {
      timeout = 15
      memory  = 128
    }
    task_batch_compute_definitions_dir           = null
    task_batch_compute_definitions_variables     = null
    task_batch_compute_definitions_variables_ssm = null
    task_definitions_dir                         = null
    task_definitions_variables                   = null
    task_definitions_variables_ssm               = null
    workflow_definitions_dir                     = null
    workflow_definitions_variables               = null
    workflow_definitions_variables_ssm           = null
    cirrus_cli_iam_role_trust_principal          = null
  }
}

variable "warning_sns_topic_arn" {
  description = "String with FilmDrop Warning SNS topic ARN"
  type        = string
}

variable "critical_sns_topic_arn" {
  description = "String with FilmDrop Critical SNS topic ARN"
  type        = string
}
