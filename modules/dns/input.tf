variable "alias_hostname" {
  description = "Host portion of the DNS alias."
  type        = string
}

variable "alias_netname" {
  description = "Network portion of the DNS alias."
  type        = string
}

variable "alias_endpoint" {
  description = "The alias of the cloudfront or other endpoint for the dns record."
  type        = string
}

variable "alias_endpoint_zone" {
  description = "Zone Id of the alias of the cloudfront or other endpoint for the dns record."
  type        = string
}

variable "zone_id" {
  description = "The DNS zone id to add the record to."
  type        = string
  default     = ""
}
