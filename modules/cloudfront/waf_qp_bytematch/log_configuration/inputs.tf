variable "web_acl_name" {
  description = "Name of the web ACL"
  type        = string
}

variable "web_acl_arn" {
  description = "Web ACL ARN"
  default     = "Web ACL ARN"
  type        = string
}

variable "filmdrop_archive_bucket_name" {
  description = "Name of existing FilmDrop Archive Bucket"
  type        = string
  default     = "CHANGEME"
}
