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

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
}

variable "private_subnet_ids" {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "security_group_id" {
  description = "Default security groups in the FilmDrop vpc"
  type        = string
}

variable "private_availability_zones" {
  description = "List of private availability zones in the FilmDrop vpc"
  type        = list(string)
}

variable "public_availability_zones" {
  description = "List of public availability zones in the FilmDrop vpc"
  type        = list(string)
}

variable "s3_logs_archive_bucket" {
  description = "Name of existing FilmDrop Archive Bucket"
  type        = string
}

variable "domain_zone" {
  description = "The DNS zone id to add the record to."
  type        = string
}

variable "analytics_inputs" {
  description = "Inputs for analytics FilmDrop deployment."
  type = object({
    app_name                    = string
    domain_alias                = string
    web_acl_id                  = string
    jupyterhub_elb_acm_cert_arn = string
    jupyterhub_elb_domain_alias = string
    create_credentials          = bool
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
    cleanup = object({
      enabled                            = bool
      asg_min_capacity                   = number
      analytics_node_limit               = number
      notifications_schedule_expressions = list(string)
      cleanup_schedule_expressions       = list(string)
    })
    eks = object({
      cluster_version    = string
      autoscaler_version = string
    })
  })
  default = {
    app_name                    = "analytics"
    domain_alias                = ""
    web_acl_id                  = ""
    jupyterhub_elb_acm_cert_arn = ""
    jupyterhub_elb_domain_alias = ""
    create_credentials          = true
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
    cleanup = {
      enabled                            = false
      asg_min_capacity                   = 1
      analytics_node_limit               = 4
      notifications_schedule_expressions = []
      cleanup_schedule_expressions       = []
    }
    eks = {
      cluster_version    = "1.32"
      autoscaler_version = "v1.32.0"
    }
  }
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
