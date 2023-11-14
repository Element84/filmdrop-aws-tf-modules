variable "zone_id" {
  description = "The DNS zone id to add the record to."
  type        = string
}

variable "name" {
  description = "Name information from the cert."
  type        = string
}

variable "type" {
  description = "Type information from the cert."
  type        = string
}

variable "records" {
  description = "Cert records entries."
  type        = list(string)
}

