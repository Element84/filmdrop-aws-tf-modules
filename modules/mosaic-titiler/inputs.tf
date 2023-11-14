variable "vpc_id" {
  description = "vpc id for deployment"
}

variable "private_subnet_ids" {
  description = "list of VPC private subnets"
  type        = list(string)
}

variable "titiler_timeout" {
  description = "Mosaic Titiler lambda timeout in seconds"
  default     = 60
}

variable "titiler_memory" {
  description = "Mosaic Titiler lambda max memory size in MB"
  default     = 1536
}

variable "titiler_stage" {
  description = "Mosaic Titiler stage name (dev/prod)"
}

variable "cpl_vsil_curl_allowed_extensions" {
  description = "CPL_VSIL_CURL_ALLOWED_EXTENSIONS lambda env var"
  default     = ".tif,.TIF,.tiff"
}

variable "gdal_cachemax" {
  description = "GDAL_CACHEMAX lambda env var"
  default     = 200
}

variable "gdal_disable_readdir_on_open" {
  description = "GDAL_DISABLE_READDIR_ON_OPEN lambda env var"
  default     = "EMPTY_DIR"
}

variable "gdal_http_merge_consecutive_ranges" {
  description = "GDAL_HTTP_MERGE_CONSECUTIVE_RANGES lambda env var"
  default     = "YES"
}

variable "gdal_http_multiplex" {
  description = "GDAL_HTTP_MULTIPLEX lambda env var"
  default     = "YES"
}

variable "gdal_http_version" {
  description = "GDAL_HTTP_VERSION lambda env var"
  default     = 2
}

variable "gdal_ingested_bytes_at_open" {
  description = "GDAL_INGESTED_BYTES_AT_OPEN lambda env var"
  default     = 32770
}

variable "pythonwarnings" {
  description = "PYTHONWARNINGS lambda env var"
  default     = "ignore"
}

variable "vsi_cache" {
  description = "VSI_CACHE lambda env var"
  default     = "TRUE"
}

variable "vsi_cache_size" {
  description = "VSI_CACHE_SIZE lambda env var"
  default     = 5000000
}

variable "aws_request_payer" {
  description = "AWS_REQUEST_PAYER lambda env var"
  default     = "requester"
}

variable "project_name" {
  description = "Project Name (must be unique for multiple deployments to a single AWS account)"
}

variable "mosaic_titiler_release_tag" {
  description = "Git release tag for: https://github.com/Element84/titiler-mosaicjson/releases"
}

variable "lambda_runtime" {
  description = "AWS lambda runtime version"
  default     = "python3.9"
}

variable "titiler_s3_bucket_arns" {
  description = "List of S3 bucket ARNs to give GetObject permissions to"
  type        = list(string)
}
