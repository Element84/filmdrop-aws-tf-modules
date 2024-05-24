
variable "titiler_timeout" {
  description = "Mosaic Titiler lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "titiler_memory" {
  description = "Mosaic Titiler lambda max memory size in MB"
  type        = number
  default     = 1536
}

variable "environment" {
  description = "Mosaic Titiler stage name (dev/prod)"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
}

variable "cpl_vsil_curl_allowed_extensions" {
  description = "CPL_VSIL_CURL_ALLOWED_EXTENSIONS lambda env var"
  default     = ".tif,.TIF,.tiff"
  type        = string
}

variable "gdal_cachemax" {
  description = "GDAL_CACHEMAX lambda env var"
  default     = 200
  type        = number
}

variable "gdal_disable_readdir_on_open" {
  description = "GDAL_DISABLE_READDIR_ON_OPEN lambda env var"
  type        = string
  default     = "EMPTY_DIR"
}

variable "gdal_http_merge_consecutive_ranges" {
  description = "GDAL_HTTP_MERGE_CONSECUTIVE_RANGES lambda env var"
  type        = string
  default     = "YES"
}

variable "gdal_http_multiplex" {
  description = "GDAL_HTTP_MULTIPLEX lambda env var"
  type        = string
  default     = "YES"
}

variable "gdal_http_version" {
  description = "GDAL_HTTP_VERSION lambda env var"
  type        = number
  default     = 2
}

variable "gdal_ingested_bytes_at_open" {
  description = "GDAL_INGESTED_BYTES_AT_OPEN lambda env var"
  type        = number
  default     = 32770
}

variable "pythonwarnings" {
  description = "PYTHONWARNINGS lambda env var"
  type        = string
  default     = "ignore"
}

variable "vsi_cache" {
  description = "VSI_CACHE lambda env var"
  type        = string
  default     = "TRUE"
}

variable "vsi_cache_size" {
  description = "VSI_CACHE_SIZE lambda env var"
  type        = number
  default     = 5000000
}

variable "aws_request_payer" {
  description = "AWS_REQUEST_PAYER lambda env var"
  type        = string
  default     = "requester"
}

variable "project_name" {
  description = "Project Name (must be unique for multiple deployments to a single AWS account)"
  type        = string
}

variable "titiler_mosaicjson_release_tag" {
  description = "Git release tag for: https://github.com/Element84/titiler-mosaicjson/releases"
  type        = string
}

variable "lambda_runtime" {
  description = "AWS lambda runtime version"
  type        = string
  default     = "python3.10"
}

variable "authorized_s3_arns" {
  description = "List of S3 bucket ARNs to give GetObject permissions to"
  type        = list(string)
}

variable "warning_titiler_invocations" {
  description = "Warning threshold for excessive TiTiler Lambda invocations (5 min)"
  type        = string
  default     = "1000"
}

variable "warning_titiler_errors" {
  description = "Warning threshold for excessive TiTiler Lambda errors (5 min)"
  type        = string
  default     = "5"
}

variable "critical_titiler_errors" {
  description = "Critical threshold for excessive TiTiler Lambda errors (5 min)"
  type        = string
  default     = "25"
}

variable "waf_allowed_url" {
  description = "The url query param in mosaic titiler GET requests, and the stac_api_root in POST requests, that should be allowed by WAF rules.  Setting to null will disable blocking behavior and set rules to count instead"
  type        = string
  default     = null
}

variable "request_host_header_override" {
  description = "If valued, this overrides the host header in the lambda request event.  Responses that build URLs from the request base URL will have this host value.  Used when the API gateway execute URL is used by cloudfront, but the cloudfront domain should be returned instead."
  type        = string
  default     = ""
}
