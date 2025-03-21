variable "stac_server_version" {
  description = "STAC Server version"
  type        = string
  default     = "v3.10.0"
}

variable "deploy_local_stac_server_artifacts" {
  description = "Deploy STAC Server artifacts for local deploy"
  type        = bool
  default     = true
}
