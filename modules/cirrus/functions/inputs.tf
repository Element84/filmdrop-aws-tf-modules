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

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
}
