variable "enabled" {
  description = "Whether to enable/disable [true/false] the cloudfront distribution"
  default     = true
}

variable "ipv6_enabled" {
  description = "Whether to enable/disable [true/false] ipv6 in the cloudfront distribution"
  default     = false
}

variable "log_cookies" {
  description = "Whether to enable/disable [true/false] cookie logging in the cloudfront distribution"
  default     = false
}

variable "default_root" {
  description = "Default object for CloudFront to return for requests at the root URL"
  default     = "index.html"
}

variable "allowed_methods" {
  description = "Which HTTP methods CloudFront processes"
  default     = ["HEAD", "GET", "OPTIONS"]
}

variable "log_prefix" {
  description = "S3 Bucket Prefix for Cloudfront Logging"
  default     = "cloudfront"
}

variable "web_acl_id" {
  description = "The id of the WAF resource to attach to the CloudFront endpoint."
  default     = ""
}

variable "domain_name" {
  description = "Cloudfront DNS domain name of S3 bucket or custom endpoint"
}

variable "origin_path" {
  description = "Cloudfront origin optional path"
  default     = ""
}

variable "domain_aliases" {
  description = "Alternate CNAMEs for Cloudfront distribution"
  default     = []
}

variable "min_ttl" {
  default = 0
}

variable "default_ttl" {
  default = 3600
}

variable "max_ttl" {
  default = 86400
}

variable "ssl_certificate_arn" {
  description = "SSL Certificate ARN from Certificate Manager for CloudFront"
  default     = ""
}

variable "minimum_protocol_version" {
  description = "Minimum version of the SSL protocol"
  default     = "TLSv1.2_2019"
}

variable "origin_http_port" {
  description = "Origin HTTP Port"
  default     = 80
}

variable "origin_https_port" {
  description = "Origin HTTPS Port"
  default     = 443
}

variable "origin_protocol_policy" {
  description = "Origin Protocol Policy"
  default     = "http-only"
}

variable "origin_ssl_protocols" {
  description = "SSL/TLS protocols CloudFront will use when communicating with the origin"
  default     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
}

variable "origin_keepalive_timeout" {
  description = "Custom KeepAlive timeout in seconds"
  default     = "60"
}

variable "origin_read_timeout" {
  description = "Custom Read timeout in seconds"
  default     = "60"
}

variable "s3_content_bucket_name" {
  description = "Name of S3 Bucket used to serve content to CloudFront, required if origin is S3"
  default     = ""
}

variable "logging_origin_id" {
  description = "CloudFront Logging Origin Id."
}

variable "logging_domain_name" {
  description = "CloudFront Logging S3 Bucket Domain Name."
}

variable "auth_header_value" {
  description = "Custom authentication header value for CloudFront Origin"
  default     = ""
}

variable "auth_header_name" {
  description = "Custom authentication header name for CloudFront Origin"
  default     = ""
}

variable "cloudfront_origin_access_identity_arn" {
  description = "Custom CloudFront Origin Access Identity ARN"
  default     = ""
}

variable "cloudfront_access_identity_path" {
  description = "Custom CloudFront Origin Access Identity Path"
  default     = ""
}

# Custom Headers, by default we support API Authorization and CORS headers.
variable "custom_http_whitelisted_headers" {
  description = "List of whitelisted http headers to have CloudFront forward to origin"
  type        = list(string)
  default     = ["Authorization", "Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method", "User-Agent"]
}

variable "custom_s3_whitelisted_headers" {
  description = "List of whitelisted http headers to have CloudFront forward to S3 origin"
  type        = list(string)
  default     = ["User-Agent"]
}

variable "custom_error_response" {
  description = "A custom aws_cloudfront_distribution.custom_error_response list to include in the distribution, e.g. for single page app error handling"
  type        = list(map(string))
  default     = []
}

variable "error_pages_id" {
  description = "CloudFront Error Pages Id"
}

variable "error_pages_domain_name" {
  description = "Cloudfront DNS domain name of S3 bucket for Custom Error Pages"
}

variable "caching_disabled" {
  description = "Disable Cloudfront Caching for s3 origin to allow large file egress"
  default     = false
}

variable "additional_cloudfront_origins" {
  description = "MAP of custom CloudFront origins, this is for cases were extra configuration is needed at the CloudFront to support path-based routing"
  type        = map
  default     = {}
}

variable "additional_origin_whitelisted_headers" {
  description = "List of whitelisted http headers to have CloudFront forward to Additional origin"
  type        = list(string)
  default     = ["User-Agent"]
}

variable "cloudfront_access" {
  description = "Describes if CloudFront has public or private restricted access."
  default     = "private"
}

variable "price_class" {
  description = "CloudFront Price Class."
  default     = "PriceClass_100"
}

variable "create_waf_rule" {
  description = "Create WAF for cloudfront"
  default     = true
}

variable "filmdrop_deployment_role" {
  description = "FilmDrop Deployment role"
  default     = "appProjectFilmDropDemoDeployRole"
}

variable "logging_bucket_name" {
  description = "Name for bucket used for cloudfront logging"
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
