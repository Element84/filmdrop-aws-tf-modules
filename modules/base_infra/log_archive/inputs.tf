variable "access_log_bucket_prefix" {
  description = "FilmDrop S3 Access Log bucket prefix"
  type        = string
  default     = ""
}

variable "archive_log_bucket_prefix" {
  description = "FilmDrop S3 Archive Log bucket prefix"
  type        = string
  default     = ""
}

variable "log_bucket_acl" {
  description = "ACL of FilmDrop S3 Logging bucket"
  type        = string
  default     = "log-delivery-write"
}

variable "environment" {
  description = "Project environment"
  type        = string
}

variable "project_name" {
  description = "Project Name"
  type        = string
}
