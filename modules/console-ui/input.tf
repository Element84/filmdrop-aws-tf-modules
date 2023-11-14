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
}

variable "filmdrop_ui_env" {
  description = "FilmDrop UI Deployment ENV file"
  type        = string
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
