variable "web_acl_name" {
    description = "Name of the web ACL"
}

variable "web_acl_arn" {
  description = "Web ACL ARN"
  default = "Web ACL ARN"
}

variable "filmdrop_archive_bucket_name" {
  description = "Name of existing FilmDrop Archive Bucket"
  default     = "CHANGEME"
}
