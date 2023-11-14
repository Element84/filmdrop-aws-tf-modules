variable "stac_id" {
  description = "STAC identifier"
  default     = "stac-server"
}

variable "stac_title" {
  description = "STAC title"
  default     = "STAC API"
}

variable "stac_description" {
  description = "STAC description"
  default     = "A STAC API using stac-server"
}

variable "log_level" {
  description = "Logging level"
  default     = "DEBUG"
}

variable "stac_docs_url" {
  description = "STAC Documentation URL"
  default     = "https://stac-utils.github.io/stac-server/"
}

variable "opensearch_host" {
  description = "OpenSearch Host"
  default     = ""
}

variable "enable_transactions_extension" {
  description = "Enable Transactions Extension"
  default     = false
}

variable "stac_api_stage" {
  description = "STAC API stage"
  default     = "dev"
}

variable "stac_api_stage_description" {
  description = "STAC API stage description"
  default     = ""
}

variable "api_lambda_timeout" {
  description = "STAC API lambda timeout in seconds"
  default     = 30
}

variable "api_lambda_memory" {
  description = "STAC API lambda max memory size in MB"
  default     = 1024
}

variable "ingest_lambda_timeout" {
  description = "STAC Ingest lambda timeout in seconds"
  default     = 60
}

variable "ingest_lambda_memory" {
  description = "STAC ingest lambda max memory size in MB"
  default     = 512
}

variable "api_rest_type" {
  description = "STAC API Gateway type"
  default     = "EDGE"
}

variable "opensearch_version" {
  description = "OpenSearch version for OpenSearch Domain"
  default     = "OpenSearch_2.3"
}

variable "opensearch_cluster_instance_type" {
  description = "OpenSearch Domain instance type"
  default     = "c6g.xlarge.elasticsearch"
}

variable "opensearch_cluster_dedicated_master_type" {
  description = "OpenSearch Domain dedicated master instance type"
  default     = "c6g.xlarge.elasticsearch"
}

variable "opensearch_cluster_instance_count" {
  description = "OpenSearch Domain instance count"
  default     = 3
}

variable "opensearch_cluster_dedicated_master_enabled" {
  description = "OpenSearch Domain dedicated master"
  default     = false
}

variable "opensearch_cluster_zone_awareness_enabled" {
  description = "OpenSearch Domain zone awareness"
  default     = true
}

variable "opensearch_cluster_availability_zone_count" {
  description = "OpenSearch Domain availability zone count"
  default     = 3
}

variable "opensearch_domain_enforce_https" {
  description = "OpenSearch Domain enforce https"
  default     = true
}

variable "opensearch_domain_min_tls" {
  description = "OpenSearch Domain minimum TLS"
  default     = "Policy-Min-TLS-1-2-2019-07"
}

variable "opensearch_domain_type" {
  description = "OpenSearch Domain type"
  default     = "opensearch"
}

variable "opensearch_ebs_enabled" {
  description = "OpenSearch EBS enabled"
  default     = true
}

variable "opensearch_ebs_volume_size" {
  description = "OpenSearch EBS volume size"
  default     = 35
}

variable "opensearch_ebs_volume_type" {
  description = "OpenSearch EBS volume type"
  default     = "gp2"
}

variable "ingest_sqs_timeout" {
  description = "STAC Ingest SQS Visibility Timeout"
  default     = 120
}

variable "ingest_sqs_max_receive_count" {
  description = "STAC Ingest SQS Max Receive Count"
  default     = 2
}

variable "ingest_sqs_receive_wait_time_seconds" {
  description = "STAC Ingest Receive Wait time"
  default     = 5
}

variable "ingest_sqs_dlq_timeout" {
  description = "STAC Ingest SQS Dead Letter Queue Visibility Timeout"
  default     = 30
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "stac_pre_hook_lambda_arn" {
  description = "STAC Pre Hook Lambda ARN"
  default     = ""
}

variable "stac_post_hook_lambda_arn" {
  description = "STAC Post-Hook Lambda ARN"
  default     = ""
}

variable "vpc_id" {
  description = "FilmDrop VPC ID"
}

variable "vpc_cidr_range" {
  description = "CIDR Range for FilmDrop vpc"
}

variable "allow_explicit_index" {
  description = "Allow OpenSearch Explicit Index"
  default     = "true"
}

variable "create_opensearch_service_linked_role" {
  description = "Enable creation of OpenSearch Service Linked Role"
  default     = true
}

variable "opensearch_advanced_security_options_enabled" {
  description = "OpenSearch advanced security options enabled"
  default     = true
}

variable "opensearch_internal_user_database_enabled" {
  description = "OpenSearch internal user database enabled"
  default     = true
}

variable "opensearch_stac_server_username" {
  description = "OpenSearch stac server username"
  default     = "stac_server"
}

variable "opensearch_admin_username" {
  description = "OpenSearch admin username"
  default     = "admin"
}

variable "collection_to_index_mappings" {
  description = "A JSON object representing collection id to index name mappings if they do not have the same names"
  default     = ""
}
