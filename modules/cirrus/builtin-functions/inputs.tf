variable "resource_prefix" {
  description = "String prefix to be used in every named resource."
  type        = string
  nullable    = false
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

variable "cirrus_lambda_version" {
  description = <<-DESCRIPTION
  (Optional) Version of Cirrus lambda to deploy.

  Defaults to the Cirrus version associated with this FilmDrop release.
  DESCRIPTION
  type        = string
  nullable    = false
  default     = "1.0.2"
}

variable "cirrus_lambda_zip_filepath" {
  description = <<-DESCRIPTION
  (Optional) Filepath to a Cirrus Lambda Dist ZIP relative to the root module of
  this Terraform deployment. If provided, will not download from GitHub Releases
  the version of Cirrus as specified in `cirrus_lambda_version`.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
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
  description = <<-DESCRIPTION
  (Optional) Cirrus `pre-batch` lambda timeout (seconds).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 15
}

variable "cirrus_pre_batch_lambda_memory" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `pre-batch` lambda memory (MB).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 128
}

variable "cirrus_post_batch_lambda_timeout" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `post-batch` lambda timeout (seconds).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 15
}

variable "cirrus_post_batch_lambda_memory" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `post-batch` lambda memory (MB).
  DESCRIPTION
  type        = number
  nullable    = false
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

variable "cirrus_publish_sns_topic_arn" {
  description = "Cirrus publish sns topic arn"
  type        = string
}

variable "vpc_id" {
  description = "FilmDrop VPC ID"
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

variable "cirrus_api_rest_type" {
  description = "Cirrus API Gateway type"
  type        = string
  default     = "EDGE"
}

variable "cirrus_private_api_additional_security_group_ids" {
  description = <<-DESCRIPTION
  Optional list of security group IDs that'll be applied to the VPC interface
  endpoints of a PRIVATE-type cirrus API Gateway. These security groups are in
  addition to the security groups that allow traffic from the private subnet
  CIDR blocks. Only applicable when `var.cirrus_api_rest_type == PRIVATE`.
  DESCRIPTION
  type        = list(string)
  default     = null
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

variable "domain_alias" {
  description = "Custom domain alias for private API Gateway endpoint"
  type        = string
  default     = ""
}

variable "private_certificate_arn" {
  description = "Private Certificate ARN for custom domain alias of private API Gateway endpoint"
  type        = string
  default     = ""
}
