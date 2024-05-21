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
