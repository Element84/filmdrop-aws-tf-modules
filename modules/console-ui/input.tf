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
}

variable "filmdrop_ui_release" {
  description = "FilmDrop UI Release"
}

variable "filmdrop_ui_env" {
  description = "FilmDrop UI Deployment ENV file"
}

variable "filmdrop_ui_config" {
  description = "FilmDrop UI Deployment Config File"
}

variable "filmdrop_ui_logo_file" {
  description = "File of the supplied custom logo"
}

variable "filmdrop_ui_logo" {
  description = "The file contents of the supplied custom logo"
}

variable "console_ui_bucket_name" {
  description = "Console UI Bucket Name"
}
