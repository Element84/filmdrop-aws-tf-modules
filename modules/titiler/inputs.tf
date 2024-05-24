variable "vpc_id" {
  description = "vpc id for codebuild to use"
  type        = string
}

variable "private_subnet_ids" {
  description = "list of subnet ids for codebuild to use"
  type        = list(any)
}

variable "security_group_ids" {
  description = "list of security group ids for codebuild to use"
  type        = list(any)
}

variable "titiler_timeout" {
  description = "Titiler lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "titiler_memory" {
  description = "Titiler lambda max memory size in MB"
  type        = number
  default     = 512
}

variable "environment" {
  description = "Titiler stage"
  type        = string
}

variable "cpl_vsil_curl_allowed_extensions" {
  description = "CPL_VSIL_CURL_ALLOWED_EXTENSIONS env var"
  type        = string
  default     = ".tif,.TIF,.tiff"
}

variable "gdal_cachemax" {
  description = "GDAL_CACHEMAX env var"
  type        = number
  default     = 200
}

variable "gdal_disable_readdir_on_open" {
  description = "GDAL_DISABLE_READDIR_ON_OPEN env var"
  type        = string
  default     = "EMPTY_DIR"
}

variable "gdal_http_merge_consecutive_ranges" {
  description = "GDAL_HTTP_MERGE_CONSECUTIVE_RANGES env var"
  type        = string
  default     = "YES"
}

variable "gdal_http_multiplex" {
  description = "GDAL_HTTP_MULTIPLEX env var"
  type        = string
  default     = "YES"
}

variable "gdal_http_version" {
  description = "GDAL_HTTP_VERSION env var"
  type        = number
  default     = 2
}

variable "gdal_ingested_bytes_at_open" {
  description = "GDAL_INGESTED_BYTES_AT_OPEN env var"
  type        = number
  default     = 32768
}

variable "pythonwarnings" {
  description = "PYTHONWARNINGS env var"
  type        = string
  default     = "ignore"
}

variable "vsi_cache" {
  description = "VSI_CACHE env var"
  type        = string
  default     = "TRUE"
}

variable "vsi_cache_size" {
  description = "VSI_CACHE_SIZE env var"
  type        = number
  default     = 5000000
}

variable "aws_request_payer" {
  description = "AWS_REQUEST_PAYER env var"
  type        = string
  default     = "requester"
}

variable "prefix" {
  description = "Titiler prefix"
  type        = string
}

variable "project_name" {
  description = "Project Name"
  type        = string
}
