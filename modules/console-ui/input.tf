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

variable "titiler_api" {
  description = "TiTiler API"
}

variable "console_ui_bucket_name" {
  description = "Console UI Bucket Name"
}
