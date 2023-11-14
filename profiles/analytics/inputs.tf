variable project_name {
  description = "Project Name"
  type        = string
  validation {
    condition     = length(var.project_name) <= 10
    error_message = "The project_name value must be a 10 or fewer characters."
  }
}

variable environment {
  description = "Project environment."
  type        = string
  validation {
    condition     = length(var.environment) <= 10
    error_message = "The environment value must be 10 or fewer characters."
  }
}

variable vpc_id {
  type        = string
  description = "ID for the VPC"
}

variable vpc_cidr {
  type        = string
  description = "CIDR for the VPC"
}

variable private_subnet_ids {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable public_subnet_ids {
  description = "List of public subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "security_group_id" {
  description = "Default security groups in the FilmDrop vpc"
  type        = string
}

variable private_availability_zones {
  description = "List of private availability zones in the FilmDrop vpc"
  type        = list(string)
}

variable public_availability_zones {
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

variable analytics_inputs {
  description = "Inputs for analytics FilmDrop deployment."
  type        = object({
    app_name                                      = string
    domain_alias                                  = string
    jupyterhub_elb_acm_cert_arn                   = string
    jupyterhub_elb_domain_alias                   = string
    create_credentials                            = bool
  })
  default       = {
    app_name                                      = "analytics"
    domain_alias                                  = ""
    jupyterhub_elb_acm_cert_arn                   = ""
    jupyterhub_elb_domain_alias                   = ""
    create_credentials                            = true
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
