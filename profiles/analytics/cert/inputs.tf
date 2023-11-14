variable "domain_zone" {
  description = "The DNS zone id to add the record to."
  type        = string
}

variable "domain_alias" {
  description = "Alternate CNAME for Cloudfront distribution"
  type        = string
  default     = ""
}
