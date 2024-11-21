variable "cirrus_prefix" {
  description = "Prefix for Cirrus-managed resources"
  type        = string
}

variable "cirrus_log_level" {
  description = "Cirrus log level (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"
}

variable "cirrus_data_bucket" {
  description = "Cirrus data bucket"
  type        = string
}

variable "cirrus_payload_bucket" {
  description = "Cirrus payload bucket"
  type        = string
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

variable "cirrus_state_dynamodb_table_name" {
  description = "Cirrus state dynamodb table name"
  type        = string
}

variable "cirrus_state_dynamodb_table_arn" {
  description = "Cirrus state dynamodb table arn"
  type        = string
}

variable "cirrus_state_event_timestreamwrite_database_name" {
  description = "Cirrus state timestream database name"
  type        = string
}

variable "cirrus_state_event_timestreamwrite_table_name" {
  description = "Cirrus state timestream table name"
  type        = string
}

variable "cirrus_state_event_timestreamwrite_table_arn" {
  description = "Cirrus state timestream table arn"
  type        = string
}

variable "cirrus_process_sqs_queue_arn" {
  description = "Cirrus process sqs queue arn"
  type        = string
}

variable "cirrus_process_sqs_queue_url" {
  description = "Cirrus process sqs queue url"
  type        = string
}

variable "cirrus_update_state_dead_letter_sqs_queue_arn" {
  description = "Cirrus update-state dead letter sqs queue arn"
  type        = string
}

variable "cirrus_workflow_event_sns_topic_arn" {
  description = "Cirrus workflow event sns topic arn"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
}

variable "api_rest_type" {
  description = "Cirrus API Gateway type"
  type        = string
  default     = "EDGE"
}

variable "cirrus_api_stage" {
  description = "Cirrus API stage"
  type        = string
  default     = "dev"
}

variable "cirrus_api_stage_description" {
  description = "Cirrus API stage description"
  type        = string
  default     = ""
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

# TODO - CVG - remove if necessary
variable "additional_lambdas" {
  description = "Map of lambda name (without cirrus prefix) to lambda detailed configuration"
  type = map(
    object({
      description     = string,
      ecr_image_uri   = optional(string, null),
      s3_bucket       = optional(string, null),
      s3_key          = optional(string, null),
      handler         = string,
      memory_mb       = optional(number, 128),
      timeout_seconds = optional(number, 10),
      runtime         = string,
      publish         = optional(bool, true),
      architectures   = optional(list(string), ["x86_64"]),
      env_vars        = optional(map(string), {}),
      vpc_enabled     = optional(bool, true)
    })
  )
  default = {}
}

variable "additional_lambda_roles" {
  description = "Map of lambda name (without cirrus prefix) to custom lambda role policy json"
  type        = map(string)
  default     = {}
}

variable "additional_warning_alarms" {
  description = "Map of lambda name (without cirrus prefix) to warning alarm configuration"
  type = map(
    object({
      evaluation_periods = optional(number, 5),
      period             = optional(number, 60),
      threshold          = optional(number, 10),
    })
  )
  default = {}
}

variable "additional_error_alarms" {
  description = "Map of lambda name (without cirrus prefix) to error alarm configuration"
  type = map(
    object({
      evaluation_periods = optional(number, 5),
      period             = optional(number, 60),
      threshold          = optional(number, 100),
    })
  )
  default = {}
}