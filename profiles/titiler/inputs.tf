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

variable "vpc_id" {
  type        = string
  description = "ID for the VPC"
}

variable "titiler_inputs" {
  description = "Inputs for titiler FilmDrop deployment."
  type = object({
    app_name                                  = string
    domain_alias                              = string
    deploy_cloudfront                         = bool
    version                                   = string
    authorized_s3_arns                        = list(string)
    mosaic_titiler_waf_allowed_url            = string
    mosaic_titiler_host_header                = string
    mosaic_tile_timeout                       = number
    web_acl_id                                = string
    is_private_endpoint                       = optional(bool)
    api_method_authorization_type             = optional(string)
    private_certificate_arn                   = optional(string)
    private_api_additional_security_group_ids = optional(list(string))
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
    app_name                                  = "titiler"
    domain_alias                              = ""
    deploy_cloudfront                         = true
    version                                   = "v0.14.0-1.0.5"
    authorized_s3_arns                        = []
    mosaic_titiler_waf_allowed_url            = ""
    mosaic_titiler_host_header                = ""
    mosaic_tile_timeout                       = 30
    web_acl_id                                = ""
    is_private_endpoint                       = false
    api_method_authorization_type             = "NONE"
    private_certificate_arn                   = ""
    private_api_additional_security_group_ids = null
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

variable "stac_url" {
  description = "STAC Server URL"
  type        = string
  default     = ""
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

variable "private_subnet_ids" {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "security_group_id" {
  description = "Default security groups in the FilmDrop vpc"
  type        = string
}
