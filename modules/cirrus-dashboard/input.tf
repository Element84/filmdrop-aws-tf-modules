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

variable "cirrus_dashboard_release" {
  description = "FilmDrop Cirrus Dashboard Release"
}

variable "cirrus_api_endpoint" {
  description = "Cirrus API Endponint"
}

variable "metrics_api_endpoint" {
  description = "Metrics API Endponint"
}

variable "cirrus_dashboard_bucket_name" {
  description = "Cirrus Dashboard Bucket Name"
}