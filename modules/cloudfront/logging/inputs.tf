variable "create_log_bucket" {
  description = "Whether to create [true/false] logging bucket for Cloudfront Distribution"
  default     = true
}

variable "log_bucket_name" {
  description = "Name of existing CloudFront Distribution Logging bucket"
  default     = ""
}

variable "log_bucket_domain_name" {
  description = "Domain Name of existing CloudFront Distribution Logging bucket"
  default     = ""
}
