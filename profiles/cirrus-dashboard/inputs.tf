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

variable "vpc_id" {
  type        = string
  description = "ID for the VPC"
}

variable "private_subnet_ids" {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "security_group_id" {
  description = "Default security groups in the FilmDrop vpc"
  type        = string
}

variable "cirrus_dashboard_inputs" {
  description = "Inputs for cirrus dashboard FilmDrop deployment."
  type = object({
    app_name     = string
    domain_alias = string
    custom_error_response = list(object({
      error_caching_min_ttl = string
      error_code            = string
      response_code         = string
      response_page_path    = string
    }))
    cirrus_api_endpoint_base = string
    cirrus_dashboard_release = string
  })
  default = {
    app_name     = "dashboard"
    domain_alias = ""
    custom_error_response = [
      {
        error_caching_min_ttl = "10"
        error_code            = "404"
        response_code         = "200"
        response_page_path    = "/"
      }
    ]
    cirrus_api_endpoint_base = ""
    cirrus_dashboard_release = "v0.5.1"
  }
}

variable "s3_logs_archive_bucket" {
  description = "Name of existing FilmDrop Archive Bucket"
  type        = string
}

variable "domain_zone" {
  description = "The DNS zone id to add the record to."
  type        = string
}

variable "domain_alias" {
  description = "Alternate CNAME for Cloudfront distribution"
  type        = string
  default     = ""
}

variable "create_log_bucket" {
  description = "Whether to create [true/false] logging bucket for Cloudfront Distribution"
  type        = bool
  default     = true
}

variable "log_bucket_name" {
  description = "Name of existing CloudFront Distribution Logging bucket"
  type        = string
  default     = ""
}

variable "log_bucket_domain_name" {
  description = "Domain Name of existing CloudFront Distribution Logging bucket"
  type        = string
  default     = ""
}
