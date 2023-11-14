variable stac_server_version {
  description = "STAC Server version"
  type        = string
  default     = "v2.2.3" 
}

variable deploy_local_stac_server_artifacts {
  description = "Deploy STAC Server artifacts for local deploy"
  type        = bool
  default     = true
}
