# Input variables to support on-going ingest from a source SNS topic (STAC catalog)

variable "source_sns_arn" {
  description = "The ARN of the SNS topic that we want to receive updates from"
  type        = string
}

variable "destination_collections_list" {
  description = "The (comma-separated) list of collections to ingest"
  type        = string
}

variable "destination_collections_min_lat" {
  description = "The minimum latitude of the bounding box area"
  type        = number
}

variable "destination_collections_min_long" {
  description = "The minimum longitude of the bounding box area"
  type        = number
}

variable "destination_collections_max_lat" {
  description = "The maximum latitude of the bounding box area"
  type        = number
}

variable "destination_collections_max_long" {
  description = "The maximum longitude of the bounding box area"
  type        = number
}

variable "ingest_sqs_arn" {
  description = "The ARN of the SQS topic that we want to publish ingest messages to"
  type        = string
}
