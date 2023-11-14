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

variable "default_root" {
  description = "Default object for CloudFront to return for requests at the root URL"
  default     = ""
}

variable "allowed_methods" {
  description = "Which HTTP methods CloudFront processes"
  default     = ["HEAD", "GET", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
}

variable "load_balancer_path" {
  description = "Load Balancer origin optional path"
  default     = ""
}

variable "origin_protocol_policy" {
  description = "Origin Protocol Policy"
  default     = "http-only"
}

variable "origin_ssl_protocols" {
  description = "SSL/TLS protocols CloudFront will use when communicating with the origin"
  default     = ["TLSv1.2", "TLSv1.1", "TLSv1"]
}

variable "custom_http_whitelisted_headers" {
  description = "List of whitelisted http headers to have CloudFront forward to origin"
  type        = list(string)
  default     = ["*"]
}

variable "load_balancer_dns_name" {
  description = "Custom Load Balancer endpoint"
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

variable "custom_error_response" {
  description = "A custom aws_cloudfront_distribution.custom_error_response list to include in the distribution, e.g. for single page app error handling"
  type        = list(map(string))
  default     = []
}
