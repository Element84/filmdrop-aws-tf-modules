variable "waf_appendix" {
  description = "Unique appendix for the WAF.  Required if the account needs more than one WAF."
}

variable "logging_bucket_name" {
  description = "Name for bucket used for cloudfront logging"
}

variable "max_message_body_size" {
  description = "The maximum size of a HTTP request body allowed by the WAF"
  default = 52428800
}

variable "max_message_body_size_check" {
  default = true
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

variable "sql_injection_check" {
  description = "Determines whether to add a SQL Injection filter. "
  default     = true
}

variable "xss_check" {
  description = "Determines whether to add a Cross Site Scripting filter. "
  default     = true
}
