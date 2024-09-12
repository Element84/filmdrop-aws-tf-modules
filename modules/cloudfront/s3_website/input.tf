variable "zone_id" {
  description = "The DNS zone id to add the record to."
  type        = string
}

variable "domain_alias" {
  description = "Alternate CNAME for Cloudfront distribution"
  type        = string
  default     = ""
}

variable "application_name" {
  description = "Application name for Cloudfront"
  type        = string
}

variable "min_ttl" {
  description = "Minimum amount of time, in seconds, that you want objects to stay in the CloudFront cache before CloudFront sends another request to the origin to determine whether the object has been updated."
  type        = number
  default     = 0
}

variable "web_acl_id" {
  description = "The id of the WAF resource to attach to the CloudFront endpoint."
  type        = string
  default     = ""
}

variable "default_ttl" {
  description = "Default amount of time, in seconds, that you want objects to stay in CloudFront caches before CloudFront forwards another request to your origin to determine whether the object has been updated"
  type        = number
  default     = 0
}

variable "max_ttl" {
  description = "Maximum amount of time, in seconds, that you want objects to stay in CloudFront caches before CloudFront queries your origin to see whether the object has been updated."
  type        = number
  default     = 0
}

variable "create_content_website" {
  description = "Create content S3 bucket with the cloudfront module"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Cloudfront DNS domain name of S3 bucket or custom endpoint"
  type        = string
  default     = ""
}

variable "custom_error_response" {
  description = "A custom aws_cloudfront_distribution.custom_error_response list to include in the distribution, e.g. for single page app error handling"
  type        = list(map(string))
  default     = []
}

variable "cf_function_name" {
  description = "Name of the CF function"
  type        = string
  default     = ""
}

variable "cf_function_runtime" {
  description = "CF function runtime"
  type        = string
  default     = "cloudfront-js-2.0"
}

variable "cf_function_code_path" {
  description = "CF function code path"
  type        = string
  default     = ""
}

variable "attach_cf_function" {
  description = "Should attach a function to CF or not"
  type        = bool
  default     = false
}

variable "cf_function_event_type" {
  description = "Eventtype for the function"
  type        = string
  default     = "viewer-request"
}

variable "create_cf_function" {
  description = "Should create a CF function or not"
  type        = bool
  default     = false
}

variable "create_cf_basicauth_function" {
  description = "Should create the BasicAuth CF function or not"
  type        = bool
  default     = false
}

variable "cf_function_arn" {
  description = "CF Function arn in case to get in input"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "dns_validation" {
  description = "Validate the certificate via a DNS record within the same module."
  type        = bool
  default     = true
}

variable "environment" {
  description = "Project environment"
  type        = string
}

variable "create_log_bucket" {
  description = "Whether to create [true/false] logging bucket for Cloudfront Distribution"
  type        = string
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

variable "filmdrop_archive_bucket_name" {
  description = "Name of existing FilmDrop Archive Bucket"
  type        = string
  default     = "CHANGEME"
}
