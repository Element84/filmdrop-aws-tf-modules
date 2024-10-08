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

variable "private_subnet_ids" {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "security_group_id" {
  description = "Default security groups in the FilmDrop vpc"
  type        = string
}

variable "cirrus_inputs" {
  description = "Inputs for FilmDrop Cirrus deployment."
  type = object({
    data_bucket    = string
    payload_bucket = string
    log_level      = string
    deploy_alarms  = bool
    custom_alarms = object({
      warning  = map(any)
      critical = map(any)
    })
    process = object({
      sqs_timeout           = number
      sqs_max_receive_count = number
    })
    state = object({
      timestream_magnetic_store_retention_period_in_days = number
      timestream_memory_store_retention_period_in_hours  = number
    })
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
  })
  default = {
    data_bucket    = "cirrus-data-bucket-name"
    payload_bucket = "cirrus-payload-bucket-name"
    log_level      = "INFO"
    deploy_alarms  = true
    custom_alarms = {
      warning  = {}
      critical = {}
    }
    process = {
      sqs_timeout           = 180
      sqs_max_receive_count = 5
    }
    state = {
      timestream_magnetic_store_retention_period_in_days = 93
      timestream_memory_store_retention_period_in_hours  = 24
    }
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
