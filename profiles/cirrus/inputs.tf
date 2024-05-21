variable "project_name" {
  description = "Project Name"
  type        = string
  validation {
    condition     = length(var.project_name) <= 10
    error_message = "The project_name value must be a 10 or fewer characters."
  }
}

variable "environment" {
  description = "Project environment."
  type        = string
  validation {
    condition     = length(var.environment) <= 10
    error_message = "The environment value must be 10 or fewer characters."
  }
}

variable "cirrus_inputs" {
  description = "Inputs for Cirrus FilmDrop deployment."
  type = object({
    data_bucket    = string
    payload_bucket = string
    process = object({
      sqs_timeout           = number
      sqs_max_receive_count = number
    })
    state = object({
      timestream_magnetic_store_retention_period_in_days = number
      timestream_memory_store_retention_period_in_hours  = number
    })
  })
  default = {
    data_bucket    = "cirrus-data-bucket-name"
    payload_bucket = "cirrus-payload-bucket-name"
    process = {
      sqs_timeout           = 180
      sqs_max_receive_count = 5
    }
    state = {
      timestream_magnetic_store_retention_period_in_days = 93
      timestream_memory_store_retention_period_in_hours  = 24
    }
  }
}
