variable "stac_id" {
  description = "STAC identifier"
  type        = string
  default     = "stac-server"
}

variable "stac_title" {
  description = "STAC title"
  type        = string
  default     = "STAC API"
}

variable "stac_description" {
  description = "STAC description"
  type        = string
  default     = "A STAC API using stac-server"
}

variable "log_level" {
  description = "Logging level (error, warn, info, http, verbose, debug, silly)"
  type        = string
  default     = "warn"
}

variable "request_logging_enabled" {
  description = "Log all requests to the server"
  type        = string
  default     = true
}

variable "stac_docs_url" {
  description = "STAC Documentation URL"
  type        = string
  default     = "https://stac-utils.github.io/stac-server/"
}

variable "opensearch_host" {
  description = "OpenSearch Host"
  type        = string
  default     = ""
}

variable "enable_transactions_extension" {
  description = "Enable Transactions Extension"
  type        = string
  default     = false
}

variable "stac_api_stage" {
  description = "STAC API stage"
  type        = string
  default     = "dev"
}

variable "stac_api_stage_description" {
  description = "STAC API stage description"
  type        = string
  default     = ""
}

variable "stac_api_rootpath" {
  description = "This should be set to an empty string when there is a cloudfront distribution in front of stac-server. This should be set to null to default to use the stac_api_stage var as the root path.  The cloudfront distros are created via the `cloudfront/apigw_endpoint` module."
  type        = string
  default     = ""
}

variable "api_lambda_timeout" {
  description = "STAC API lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "api_lambda_memory" {
  description = "STAC API lambda max memory size in MB"
  type        = number
  default     = 1024
}

variable "ingest_lambda_timeout" {
  description = "STAC Ingest lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "ingest_lambda_memory" {
  description = "STAC ingest lambda max memory size in MB"
  type        = number
  default     = 512
}

variable "reserved_concurrent_executions" {
  description = "STAC ingest lambda reserved concurrent executions (max concurrency)"
  type        = number
  default     = 10
}

variable "pre_hook_lambda_timeout" {
  description = "STAC API auth pre-hook lambda timeout in seconds"
  type        = number
  default     = 25
}

variable "pre_hook_lambda_memory" {
  description = "STAC API auth pre-hook lambda max memory size in MB"
  type        = number
  default     = 128
}

variable "api_rest_type" {
  description = "STAC API Gateway type"
  type        = string
  default     = "EDGE"
}

variable "opensearch_version" {
  description = "OpenSearch version for OpenSearch Domain"
  type        = string
  default     = "OpenSearch_2.9"
}

variable "opensearch_cluster_instance_type" {
  description = "OpenSearch Domain instance type"
  type        = string
  default     = "c6g.large.search"
}

variable "opensearch_cluster_dedicated_master_type" {
  description = "OpenSearch Domain dedicated master instance type"
  type        = string
  default     = "m6g.large.search"
}

variable "opensearch_cluster_instance_count" {
  description = "OpenSearch Domain instance count"
  type        = number
  default     = 3
}

variable "opensearch_cluster_dedicated_master_enabled" {
  description = "OpenSearch Domain dedicated master"
  type        = bool
  default     = false
}

variable "opensearch_cluster_zone_awareness_enabled" {
  description = "OpenSearch Domain zone awareness"
  type        = bool
  default     = true
}

variable "opensearch_cluster_availability_zone_count" {
  description = "OpenSearch Domain availability zone count"
  type        = number
  default     = 3
}

variable "opensearch_domain_enforce_https" {
  description = "OpenSearch Domain enforce https"
  type        = bool
  default     = true
}

variable "opensearch_domain_min_tls" {
  description = "OpenSearch Domain minimum TLS"
  type        = string
  default     = "Policy-Min-TLS-1-2-2019-07"
}

variable "opensearch_ebs_volume_size" {
  description = "OpenSearch EBS volume size"
  type        = number
  default     = 35
}

variable "opensearch_ebs_volume_type" {
  description = "OpenSearch EBS volume type"
  type        = string
  default     = "gp3"
}

variable "ingest_sqs_timeout" {
  description = "STAC Ingest SQS Visibility Timeout"
  type        = number
  default     = 120
}

variable "ingest_sqs_max_receive_count" {
  description = "STAC Ingest SQS Max Receive Count"
  type        = number
  default     = 2
}

variable "ingest_sqs_receive_wait_time_seconds" {
  description = "STAC Ingest Receive Wait time"
  type        = number
  default     = 5
}

variable "ingest_sqs_dlq_timeout" {
  description = "STAC Ingest SQS Dead Letter Queue Visibility Timeout"
  type        = number
  default     = 30
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
}

variable "stac_server_pre_hook_lambda_arn" {
  description = "STAC API Pre-Hook Lambda ARN"
  type        = string
  default     = ""
}

variable "stac_server_auth_pre_hook_enabled" {
  description = "STAC API Pre-Hook Auth Lambda Enabled"
  type        = bool
  default     = false
}

variable "stac_server_post_hook_lambda_arn" {
  description = "STAC API Post-Hook Lambda ARN"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "FilmDrop VPC ID"
  type        = string
}

variable "vpc_cidr_range" {
  description = "CIDR Range for FilmDrop vpc"
  type        = string
}

variable "allow_explicit_index" {
  description = "Allow OpenSearch Explicit Index"
  type        = string
  default     = "true"
}

variable "opensearch_advanced_security_options_enabled" {
  description = "OpenSearch advanced security options enabled"
  type        = bool
  default     = true
}

variable "opensearch_internal_user_database_enabled" {
  description = "OpenSearch internal user database enabled"
  type        = bool
  default     = true
}

variable "opensearch_stac_server_username" {
  description = "OpenSearch stac server username"
  type        = string
  default     = "stac_server"
}

variable "opensearch_stac_server_domain_name_override" {
  description = "This optionally overrides the OpenSearch server name.  Since this name can't change after the server has been created, it is provided so that any changes to the default name don't require tearing down the server on future TF updates."
  type        = string
  default     = null
}

variable "opensearch_admin_username" {
  description = "OpenSearch admin username"
  type        = string
  default     = "admin"
}

variable "collection_to_index_mappings" {
  description = "A JSON object representing collection id to index name mappings if they do not have the same names"
  type        = string
  default     = ""
}

variable "ingest_sns_topic_arns" {
  description = "List of additional Ingest SNS topic arns to subscribe to stac server"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "stac_server_s3_bucket_arns" {
  description = "List of S3 bucket ARNs to give GetObject permissions to"
  type        = list(string)
  default     = []
}

variable "opensearch_cluster_dedicated_master_count" {
  description = "Number of dedicated main nodes in the cluster."
  type        = number
  default     = 3
}

variable deploy_stac_server_opensearch_serverless {
  type        = bool
  default     = false
  description = "Deploy FilmDrop Stac-Server with OpenSearch Serverless. If False, Stac-server will be deployed with a classic OpenSearch domain."
}
