variable "credentials_name_prefix" {
  description = "The name prefix for admin credentials."
  type        = string
}

variable "create_credentials" {
  description = "Create admin credentials."
  type        = bool
  default     = true
}
