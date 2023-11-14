variable "vpc_private_subnet_ids" {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "FilmDrop VPC ID"
  type        = string
}

variable "filmdrop_ui_release" {
  description = "FilmDrop UI Release"
  type        = string
  validation {
    condition     = substr(var.filmdrop_ui_release, 0, 1) == "v" && substr(var.filmdrop_ui_release, 1, 2) >= 4
    error_message = "The filmdrop_ui_release value must be a filmdrop-ui release >= v4.0.0"
  }
}

variable "filmdrop_ui_config" {
  description = "FilmDrop UI Deployment Config File"
  type        = string
}

variable "filmdrop_ui_logo_file" {
  description = "File of the supplied custom logo"
  type        = string
}

variable "filmdrop_ui_logo" {
  description = "The file contents of the supplied custom logo"
  type        = string
}

variable "console_ui_bucket_name" {
  description = "Console UI Bucket Name"
  type        = string
}
