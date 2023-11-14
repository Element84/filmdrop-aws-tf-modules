variable "alias_address" {
  description = "The DNS aliases."
  default     = ""
}

variable "zone_id" {
  description = "The DNS zone id to add the record to."
  default     = ""
}

variable "dns_validation" {
  description = "Validate the certificate via a DNS record within the same module."
  default     = "true"
}

variable "validation_method" {
  description = "Validation method for ACM certificate."
  default     = "DNS"
}
