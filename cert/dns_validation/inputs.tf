variable "zone_id" {
  description = "The DNS zone id to add the record to."
}

variable "name" {
  description = "Name information from the cert."
}

variable "type" {
  description = "Type information from the cert."
}

variable "records" {
  description = "Cert records entries."
}

variable "alias_address" {
  description = "The certificate fqdns names list."
}
