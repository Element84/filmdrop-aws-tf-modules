variable "logging_bucket_name" {
  description = "Name for bucket used for cloudfront logging"
  type        = string
}

variable "max_message_body_size" {
  description = "The maximum size of a HTTP request body allowed by the WAF"
  type        = number
  default     = 52428800
}

variable "country_blocklist" {
  description = "List of countries to block access to. Use AWS country code. "
  type        = set(string)
  default     = []
}

variable "ip_blocklist" {
  description = "List of ip cidr ranges to block access to. "
  type        = set(string)
  default     = []
}

variable "whitelist_ips" {
  description = "List of ips to filter access for."
  type        = set(string)
  default     = []
}

variable "environment" {
  description = "Project environment."
  type        = string
  validation {
    condition     = length(var.environment) <= 10
    error_message = "The environment value must be 10 or fewer characters."
  }
}

variable "project_name" {
  description = "Project Name"
  type        = string
  validation {
    condition     = length(var.project_name) <= 10
    error_message = "The project_name value must be a 10 or fewer characters."
  }
}
