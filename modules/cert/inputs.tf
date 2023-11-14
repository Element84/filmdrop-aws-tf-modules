variable "alias_address" {
  description = "The DNS aliases."
  type        = string
  default     = ""
}

variable "zone_id" {
  description = "The DNS zone id to add the record to."
  type        = string
  default     = ""
}

variable "dns_validation" {
  description = "Validate the certificate via a DNS record within the same module."
  type        = bool
  default     = true
}

variable "validation_method" {
  description = "Validation method for ACM certificate."
  type        = string
  default     = "DNS"
}

variable "cert_ttl" {
  description = "The TTL of the record."
  type        = number
  default     = 60
}
