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

variable "console_ui_inputs" {
  description = "Inputs for console-ui FilmDrop deployment."
  type = object({
    app_name          = string
    domain_alias      = string
    deploy_cloudfront = bool
    deploy_s3_bucket  = optional(bool)
    external_content_bucket = optional(object({
      external_content_website_bucket_name         = optional(string)
      external_content_bucket_regional_domain_name = optional(string)
    }))
    web_acl_id = string
    custom_error_response = list(object({
      error_caching_min_ttl = string
      error_code            = string
      response_code         = string
      response_page_path    = string
    }))
    version                 = string
    filmdrop_ui_config_file = string
    filmdrop_ui_logo_file   = string
    filmdrop_ui_logo        = string
    auth_function = object({
      cf_function_name             = string
      cf_function_runtime          = string
      cf_function_code_path        = string
      attach_cf_function           = bool
      cf_function_event_type       = string
      create_cf_function           = bool
      create_cf_basicauth_function = bool
      cf_function_arn              = string
    })
  })
  default = {
    app_name          = "console"
    domain_alias      = ""
    deploy_cloudfront = true
    deploy_s3_bucket  = true
    external_content_bucket = {
      external_content_website_bucket_name         = ""
      external_content_bucket_regional_domain_name = ""
    }
    web_acl_id = ""
    custom_error_response = [
      {
        error_caching_min_ttl = "10"
        error_code            = "404"
        response_code         = "200"
        response_page_path    = "/"
      }
    ]
    version                 = "v5.3.0"
    filmdrop_ui_config_file = "./default-config/config.dev.json"
    filmdrop_ui_logo_file   = "./default-config/logo.png"
    filmdrop_ui_logo        = "bm9uZQo=" # Base64: 'none'
    auth_function = {
      cf_function_name             = ""
      cf_function_runtime          = "cloudfront-js-2.0"
      cf_function_code_path        = ""
      attach_cf_function           = false
      cf_function_event_type       = "viewer-request"
      create_cf_function           = false
      create_cf_basicauth_function = false
      cf_function_arn              = ""
    }
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

variable "fd_web_acl_id" {
  description = "The id of the FilmDrop WAF resource."
  type        = string
  default     = ""
}
