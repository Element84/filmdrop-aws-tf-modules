variable "waf_appendix" {
  description = "Unique appendix for the WAF.  Required if the account needs more than one WAF."
  type        = string
}

variable "logging_bucket_name" {
  description = "Name for bucket used for cloudfront logging"
  type        = string
}

variable "max_message_body_size" {
  description = "The maximum size of a HTTP request body allowed by the WAF"
  type        = number
  default     = 52428800
}

variable "country_blocklist" {
  description = "List of countries to block access to. Use AWS country code. "
  type        = set(string)
  default     = []
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

