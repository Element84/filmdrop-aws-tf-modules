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

variable "stac_version" {
  description = "STAC version"
  default     = "1.0.0"
}

variable "log_level" {
  description = "Logging level"
  default     = "DEBUG"
}

variable "os_batch_size" {
  description = "ElasticSearch Batch Size"
  default     = 500
}

variable "stac_docs_url" {
  description = "STAC Documentation URL"
  default     = "https://stac-utils.github.io/stac-server/"
}

variable "os_host" {
  description = "ElasticSearch Host"
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

variable "elasticsearch_version" {
  description = "ElasticSearch version for ES Domain"
  default     = "OpenSearch_2.3"
}

variable "os_cluster_instance_type" {
  description = "ES Domain instance type"
  default     = "t3.small.elasticsearch"
}

variable "os_cluster_instance_count" {
  description = "ES Domain instance count"
  default     = 2
}

variable "os_cluster_dedicated_master_enabled" {
  description = "ES Domain dedicated master"
  default     = false
}

variable "os_cluster_zone_awareness_enabled" {
  description = "ES Domain zone awareness"
  default     = true
}

variable "os_domain_enforce_https" {
  description = "ES Domain enforce https"
  default     = true
}

variable "os_domain_min_tls" {
  description = "ES Domain minimum TLS"
  default     = "Policy-Min-TLS-1-2-2019-07"
}

variable "os_domain_type" {
  description = "ES Domain type"
  default     = "os"
}

variable "os_ebs_enabled" {
  description = "ES EBS enabled"
  default     = true
}

variable "os_ebs_volume_size" {
  description = "ES EBS volume size"
  default     = 35
}

variable "os_ebs_volume_type" {
  description = "ES EBS volume type"
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

variable "stac_pre_hook_lambda" {
  description = "STAC Pre Hook Lambda Name"
  default     = ""
}

variable "stac_pre_hook_lambda_path" {
  description = "STAC Pre Hook Lambda Path"
  default     = ""
}

variable "stac_pre_hook_lambda_token" {
  description = "STAC Pre Hook Lambda Token"
  default     = ""
}

variable "stac_pre_hook_lambda_token_txn" {
  description = "STAC Pre Hook Lambda Token TXN"
  default     = ""
}

variable "stac_post_hook_lambda" {
  description = "STAC Post Hook Lambda Name"
  default     = ""
}

variable "stac_post_hook_lambda_path" {
  description = "STAC Post Hook Lambda Path"
  default     = ""
}

variable "pre_hook_lambda_timeout" {
  description = "STAC Pre Hook lambda timeout in seconds"
  default     = 25
}

variable "pre_hook_lambda_memory" {
  description = "STAC Pre Hook lambda max memory size in MB"
  default     = 512
}

variable "post_hook_lambda_timeout" {
  description = "STAC Post Hook lambda timeout in seconds"
  default     = 25
}

variable "post_hook_lambda_memory" {
  description = "STAC Post Hook lambda max memory size in MB"
  default     = 512
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

variable "create_os_service_linked_role" {
  description = "Enable creation of OpenSearch Service Linked Role"
  default     = true
}
