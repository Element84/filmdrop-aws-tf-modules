variable "enabled" {
  description = "Whether to enable/disable [true/false] the cloudfront distribution"
  type        = bool
  default     = true
}

variable "ipv6_enabled" {
  description = "Whether to enable/disable [true/false] ipv6 in the cloudfront distribution"
  type        = bool
  default     = false
}

variable "log_cookies" {
  description = "Whether to enable/disable [true/false] cookie logging in the cloudfront distribution"
  type        = bool
  default     = false
}

variable "default_root" {
  description = "Default object for CloudFront to return for requests at the root URL"
  type        = string
  default     = "index.html"
}

variable "web_acl_id" {
  description = "The id of the WAF resource to attach to the CloudFront endpoint."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Cloudfront DNS domain name of S3 bucket or custom endpoint"
  type        = string
}

variable "origin_path" {
  description = "Cloudfront origin optional path"
  type        = string
  default     = ""
}

variable "domain_aliases" {
  description = "Alternate CNAMEs for Cloudfront distribution"
  type        = list(string)
  default     = []
}

variable "min_ttl" {
  description = "Minimum amount of time, in seconds, that you want objects to stay in the CloudFront cache before CloudFront sends another request to the origin to determine whether the object has been updated."
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default amount of time, in seconds, that you want objects to stay in CloudFront caches before CloudFront forwards another request to your origin to determine whether the object has been updated"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum amount of time, in seconds, that you want objects to stay in CloudFront caches before CloudFront queries your origin to see whether the object has been updated."
  type        = number
  default     = 86400
}

variable "ssl_certificate_arn" {
  description = "SSL Certificate ARN from Certificate Manager for CloudFront"
  type        = string
  default     = ""
}

variable "minimum_protocol_version" {
  description = "Minimum version of the SSL protocol"
  type        = string
  default     = "TLSv1.2_2019"
}

variable "origin_http_port" {
  description = "Origin HTTP Port"
  type        = number
  default     = 80
}

variable "origin_https_port" {
  description = "Origin HTTPS Port"
  type        = number
  default     = 443
}

variable "origin_protocol_policy" {
  description = "Origin Protocol Policy"
  type        = string
  default     = "http-only"
}

variable "origin_ssl_protocols" {
  description = "SSL/TLS protocols CloudFront will use when communicating with the origin"
  type        = list(string)
  default     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
}

variable "origin_keepalive_timeout" {
  description = "Custom KeepAlive timeout in seconds"
  type        = string
  default     = "60"
}

variable "origin_read_timeout" {
  description = "Custom Read timeout in seconds"
  type        = string
  default     = "60"
}

variable "auth_header_value" {
  description = "Custom authentication header value for CloudFront Origin"
  type        = string
  default     = ""
}

variable "auth_header_name" {
  description = "Custom authentication header name for CloudFront Origin"
  type        = string
  default     = ""
}

# Custom Headers, by default we support API Authorization and CORS headers.
variable "custom_http_whitelisted_headers" {
  description = "List of whitelisted http headers to have CloudFront forward to origin"
  type        = list(string)
  default     = ["Authorization", "Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method", "User-Agent", "Referer", "X-Forwarded-For", "filmdrop-authorized"]
}

variable "custom_error_response" {
  description = "A custom error response list for error handling"
  type        = list(map(string))
  default     = []
}

variable "price_class" {
  description = "CloudFront Price Class."
  type        = string
  default     = "PriceClass_100"
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

variable "application_name" {
  description = "Application name for Cloudfront"
  type        = string
}
