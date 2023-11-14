variable "log_bucket_name" {
  description = "Name of FilmDrop S3 Logging bucket"
  default     = "filmdrop-s3-access-logs"
}

variable "log_bucket_acl" {
  description = "ACL of FilmDrop S3 Logging bucket"
  default     = "log-delivery-write"
}
