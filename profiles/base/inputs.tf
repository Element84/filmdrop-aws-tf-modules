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
  default     = ""
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
  default     = ""
}

variable "public_subnets_az_to_id_map" {
  type        = map(any)
  description = "Map with the availability zone to the subnet-id for public subnets. If deploy_vpc = true, then specify the map with az => subnet-cidr-range instead."
  default     = {}
}

variable "private_subnets_az_to_id_map" {
  type        = map(any)
  description = "Map with the availability zone to the subnet-id for private subnets. If deploy_vpc = true, then specify the map with az => subnet-cidr-range instead."
  default     = {}
}

variable "security_group_id" {
  type        = string
  description = "ID for the Security Group in the FilmDrop VPC"
  default     = ""
}

variable "sns_warning_subscriptions_map" {
  type    = map(any)
  default = {}
}

variable "sns_critical_subscriptions_map" {
  type    = map(any)
  default = {}
}

variable "s3_access_log_bucket" {
  description = "FilmDrop S3 Access Log Bucket Name"
  type        = string
  default     = ""
}

variable "s3_logs_archive_bucket" {
  description = "FilmDrop S3 Archive Log Bucket Name"
  type        = string
  default     = ""
}

variable "deploy_vpc" {
  type        = bool
  default     = false
  description = "Deploy FilmDrop VPC stack"
}

variable "deploy_log_archive" {
  type        = bool
  default     = true
  description = "Deploy FilmDrop Log Archive Bucket"
}

variable "deploy_vpc_search" {
  type        = bool
  default     = true
  description = "Perform a FilmDrop VPC search"
}

variable "deploy_waf_rule" {
  description = "Deploy FilmDrop WAF rule"
  type        = bool
  default     = true
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

variable "ext_web_acl_id" {
  description = "The id of the external WAF resource to attach to the FilmDrop CloudFront Endpoints."
  type        = string
  default     = ""
}
