variable "zone_id" {
  description = "The DNS zone id to add the record to."
}

variable "domain_alias" {
  description = "Alternate CNAME for Cloudfront distribution"
}

variable "application_name" {
  description = "Application name for Cloudfront"
}

variable "cloudfront_origin_access_identity_arn" {
  description = "Custom CloudFront Origin Access Identity ARN"
}

variable "cloudfront_access_identity_path" {
  description = "Custom CloudFront Origin Access Identity Path"
}

variable "min_ttl" {
  default = 0
}

variable "default_ttl" {
  default = 0
}

variable "max_ttl" {
  default = 0
}

variable "logging_origin_id" {
  description = "CloudFront Logging Origin Id."
}

variable "logging_domain_name" {
  description = "CloudFront Logging S3 Bucket Domain Name."
}

variable "error_pages_id" {
  description = "CloudFront Error Pages Id"
}

variable "error_pages_domain_name" {
  description = "Cloudfront DNS domain name of S3 bucket for Custom Error Pages"
}

variable "logging_bucket_name" {
  description = "Name for bucket used for cloudfront logging"
}

variable "create_content_website" {
  description = "Create content S3 bucket with the cloudfront module"
  default     = true
}

variable "domain_name" {
  description = "Cloudfront DNS domain name of S3 bucket or custom endpoint"
  default     = ""
}

variable "custom_error_response" {
  description = "A custom aws_cloudfront_distribution.custom_error_response list to include in the distribution, e.g. for single page app error handling"
  type        = list(map(string))
  default     = []
}