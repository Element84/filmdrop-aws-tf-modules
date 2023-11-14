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

variable "cloudfront_origin_access_identity_arn" {
  description = "Custom CloudFront Origin Access Identity ARN"
  type        = string
}

variable "cloudfront_access_identity_path" {
  description = "Custom CloudFront Origin Access Identity Path"
  type        = string
}

variable "logging_origin_id" {
  description = "CloudFront Logging Origin Id."
  type        = string
}

variable "logging_domain_name" {
  description = "CloudFront Logging S3 Bucket Domain Name."
  type        = string
}

variable "error_pages_id" {
  description = "CloudFront Error Pages Id"
  type        = string
}

variable "error_pages_domain_name" {
  description = "Cloudfront DNS domain name of S3 bucket for Custom Error Pages"
  type        = string
}

variable "logging_bucket_name" {
  description = "Name for bucket used for cloudfront logging"
  type        = string
}

variable "default_root" {
  description = "Default object for CloudFront to return for requests at the root URL"
  type        = string
  default     = ""
}

variable "allowed_methods" {
  description = "Which HTTP methods CloudFront processes"
  type        = list(string)
  default     = ["HEAD", "GET", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
}

variable "load_balancer_path" {
  description = "Load Balancer origin optional path"
  type        = string
  default     = ""
}

variable "origin_protocol_policy" {
  description = "Origin Protocol Policy"
  type        = string
  default     = "http-only"
}

variable "origin_ssl_protocols" {
  description = "SSL/TLS protocols CloudFront will use when communicating with the origin"
  type        = list(string)
  default     = ["TLSv1.2", "TLSv1.1", "TLSv1"]
}

variable "custom_http_whitelisted_headers" {
  description = "List of whitelisted http headers to have CloudFront forward to origin"
  type        = list(string)
  default     = ["*"]
}

variable "load_balancer_dns_name" {
  description = "Custom Load Balancer endpoint"
  type        = string
}


variable "min_ttl" {
  description = "Minimum amount of time, in seconds, that you want objects to stay in the CloudFront cache before CloudFront sends another request to the origin to determine whether the object has been updated."
  type        = number
  default     = 0
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

variable "custom_error_response" {
  description = "A custom aws_cloudfront_distribution.custom_error_response list to include in the distribution, e.g. for single page app error handling"
  type        = list(map(string))
  default     = []
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
