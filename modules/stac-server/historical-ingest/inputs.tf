variable "include_historical_ingest" {
  description = "A true/false value for whether or not to perform historical ingest"
  type        = bool
}

variable "source_catalog_url" {
  description = "The URL of the source STAC catalog API"
  type        = string
}

variable "destination_catalog_url" {
  description = "The URL of the destination STAC catalog API"
  type        = string
}

variable "destination_collections_list" {
  description = "The (comma-separated) list of collections to ingest"
  type        = string
}

variable "destination_collections_min_lat" {
  description = "The minimum latitude of the bounding box area"
  type        = string
}

variable "destination_collections_min_long" {
  description = "The minimum longitude of the bounding box area"
  type        = string
}

variable "destination_collections_max_lat" {
  description = "The maximum latitude of the bounding box area"
  type        = string
}

variable "destination_collections_max_long" {
  description = "The maximum longitude of the bounding box area"
  type        = string
}

variable "date_start" {
  description = "The start date for the historical ingest"
  type        = string
}
variable "date_end" {
  description = "The end date for the historical ingest"
  type        = string
}

variable "ingest_sqs_url" {
  description = "The URL of the SQS topic that we want to publish ingest messages to"
  type        = string
}

variable "stac_server_name_prefix" {
  description = "The parent stac-server name prefix for aws resources"
  type        = string
}

variable "stac_server_lambda_iam_role_arn" {
  description = "The parent stac-server IAM role with access to opensearch"
  type        = string
}