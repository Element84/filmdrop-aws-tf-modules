variable "environment" {
  description = "Project environment"
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

variable "cirrus_process_sqs_timeout" {
  description = "Cirrus Process SQS Visibility Timeout"
  type        = number
  default     = 180
}

variable "cirrus_process_sqs_max_receive_count" {
  description = "Cirrus Process SQS Max Receive Count"
  type        = number
  default     = 5
}

variable "cirrus_timestream_magnetic_store_retention_period_in_days" {
  description = "Cirrus Timestream duration for which data must be stored in the magnetic store"
  type        = number
  default     = 93
}

variable "cirrus_timestream_memory_store_retention_period_in_hours" {
  description = "Cirrus Timestream duration for which data must be stored in the memory store"
  type        = number
  default     = 24
}

variable "cirrus_data_bucket" {
  description = "Cirrus data bucket"
  type        = string
}

variable "cirrus_payload_bucket" {
  description = "Cirrus payload bucket"
  type        = string
}

variable "cirrus_log_level" {
  description = "Cirrus log level (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"
}

variable "cirrus_api_lambda_timeout" {
  description = "Cirrus API lambda timeout (sec)"
  type        = number
  default     = 10
}

variable "cirrus_api_lambda_memory" {
  description = "Cirrus API lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_process_lambda_timeout" {
  description = "Cirrus process lambda timeout (sec)"
  type        = number
  default     = 10
}

variable "cirrus_process_lambda_memory" {
  description = "Cirrus process lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_process_lambda_reserved_concurrency" {
  description = "Cirrus process reserved concurrency"
  type        = number
  default     = 16
}

variable "cirrus_update_state_lambda_timeout" {
  description = "Cirrus update-state lambda timeout (sec)"
  type        = number
  default     = 15
}

variable "cirrus_update_state_lambda_memory" {
  description = "Cirrus update-state lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_pre_batch_lambda_timeout" {
  description = "Cirrus pre-batch lambda timeout (sec)"
  type        = number
  default     = 15
}

variable "cirrus_pre_batch_lambda_memory" {
  description = "Cirrus pre-batch lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_post_batch_lambda_timeout" {
  description = "Cirrus post-batch lambda timeout (sec)"
  type        = number
  default     = 15
}

variable "cirrus_post_batch_lambda_memory" {
  description = "Cirrus post-batch lambda memory (MB)"
  type        = number
  default     = 128
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
}

variable "warning_sns_topic_arn" {
  description = "String with FilmDrop Warning SNS topic ARN"
  type        = string
}

variable "critical_sns_topic_arn" {
  description = "String with FilmDrop Critical SNS topic ARN"
  type        = string
}

variable "deploy_alarms" {
  type        = bool
  default     = true
  description = "Deploy Cirrus Alarms stack"
}

variable "custom_cloudwatch_warning_alarms_map" {
  description = "Map with custom CloudWatch Warning Alarms"
  type        = map(any)
  default     = {}
}

variable "custom_cloudwatch_critical_alarms_map" {
  description = "Map with custom CloudWatch Critical Alarms"
  type        = map(any)
  default     = {}
}
