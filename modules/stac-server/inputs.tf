variable "stac_id" {
  description = "STAC identifier"
  type        = string
  default     = "stac-server"
  nullable    = false
}

variable "stac_title" {
  description = "STAC title"
  type        = string
  default     = "STAC API"
  nullable    = false
}

variable "stac_description" {
  description = "STAC description"
  type        = string
  default     = "A STAC API using stac-server"
  nullable    = false
}

variable "log_level" {
  description = "Logging level (error, warn, info, http, verbose, debug, silly)"
  type        = string
  default     = "warn"
}

variable "request_logging_enabled" {
  description = "Log all requests to the server"
  type        = bool
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
  type        = bool
  default     = false
}

variable "enable_collections_authx" {
  description = "Enable Collections Authx"
  type        = bool
  default     = false
}

variable "enable_filter_authx" {
  description = "Enable Filter Authx"
  type        = bool
  default     = false
}


variable "enable_response_compression" {
  description = "Enable Response Compression"
  type        = bool
  default     = false
}

variable "items_max_limit" {
  description = "Items Max Limit"
  type        = number
  default     = 100
}

variable "enable_ingest_action_truncate" {
  description = "Enable Ingest Action Truncate"
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
  description = <<-DESCRIPTION
  If stac-server has a cloudfront distribution, this should be an empty string.
  If stac-server does not have a cloudfront distribution, the api_rest_type is
  PRIVATE, and you're managing a custom API Gateway domain outside of this module,
  this should be an empty string.
  If neither is true, the stac_api_stage var should be used.
  DESCRIPTION
  type        = string
  default     = ""
}

variable "api_lambda" {
  description = <<-DESCRIPTION
  (optional, object) Parameters for the stac-server API Lambda function.
    - zip_filepath: (optional, string) Filepath to a ZIP that implements the
      stac-server API Lambda. Path is relative to the root module of this
      deployment. Overrides the default ZIP included with this module.
    - runtime: (optional, string) Lambda runtime.
    - handler: (optional, string) Lambda handler.
    - memory_mb: (optional, number) Lambda max memory (MB).
    - timeout_seconds (optional, number) Lambda timeout (seconds).
  DESCRIPTION

  type = object({
    zip_filepath    = optional(string)
    runtime         = optional(string, "nodejs20.x")
    handler         = optional(string, "index.handler")
    memory_mb       = optional(number, 1024)
    timeout_seconds = optional(number, 30)
  })
  default = {
    zip_filepath    = null
    runtime         = "nodejs20.x"
    handler         = "index.handler"
    memory_mb       = 1024
    timeout_seconds = 30
  }
  nullable = false
}

variable "ingest_lambda" {
  description = <<-DESCRIPTION
  (optional, object) Parameters for the stac-server ingest Lambda function.
    - zip_filepath: (optional, string) Filepath to a ZIP that implements the
      stac-server ingest Lambda. Path is relative to the root module of this
      deployment. Overrides the default ZIP included with this module.
    - runtime: (optional, string) Lambda runtime.
    - handler: (optional, string) Lambda handler.
    - memory_mb: (optional, number) Lambda max memory (MB).
    - timeout_seconds (optional, number) Lambda timeout (seconds).
  DESCRIPTION

  type = object({
    zip_filepath    = optional(string)
    runtime         = optional(string, "nodejs20.x")
    handler         = optional(string, "index.handler")
    memory_mb       = optional(number, 512)
    timeout_seconds = optional(number, 60)
  })
  default = {
    zip_filepath    = null
    runtime         = "nodejs20.x"
    handler         = "index.handler"
    memory_mb       = 512
    timeout_seconds = 60
  }
  nullable = false
}

variable "pre_hook_lambda" {
  description = <<-DESCRIPTION
  (optional, object) Parameters for the stac-server pre-hook Lambda function.
    - zip_filepath: (optional, string) Filepath to a ZIP that implements the
      stac-server auth pre-hook Lambda. Path is relative to the root module of
      this deployment. Overrides the default ZIP included with this module.
    - runtime: (optional, string) Lambda runtime.
    - handler: (optional, string) Lambda handler.
    - memory_mb: (optional, number) Lambda max memory (MB).
    - timeout_seconds (optional, number) Lambda timeout (seconds).
  DESCRIPTION

  type = object({
    zip_filepath    = optional(string)
    runtime         = optional(string, "nodejs20.x")
    handler         = optional(string, "index.handler")
    memory_mb       = optional(number, 128)
    timeout_seconds = optional(number, 25)
  })
  default = {
    zip_filepath    = null
    runtime         = "nodejs20.x"
    handler         = "index.handler"
    memory_mb       = 128
    timeout_seconds = 25
  }
  nullable = false
}

variable "reserved_concurrent_executions" {
  description = "STAC ingest lambda reserved concurrent executions (max concurrency)"
  type        = number
  default     = 10
}

variable "api_rest_type" {
  description = "STAC API Gateway type"
  type        = string
  default     = "EDGE"
}

variable "api_method_authorization_type" {
  description = "STAC API Gateway method authorization type"
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "CUSTOM", "AWS_IAM", "COGNITO_USER_POOLS"], var.api_method_authorization_type)
    error_message = "STAC API method authorization type must be one of: NONE, CUSTOM, AWS_IAM, or COGNITO_USER_POOLS."
  }
}

variable "private_api_additional_security_group_ids" {
  description = <<-DESCRIPTION
  Optional list of security group IDs that'll be applied to the VPC interface
  endpoints of a PRIVATE-type stac-server API Gateway. These security groups are
  in addition to the security groups that allow traffic from the private subnet
  CIDR blocks. Only applicable when `var.api_rest_type == PRIVATE`.
  DESCRIPTION
  type        = list(string)
  default     = null
}

variable "opensearch_version" {
  description = "OpenSearch version for OpenSearch Domain"
  type        = string
  default     = "OpenSearch_2.17"
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

variable "additional_ingest_sqs_senders_arns" {
  description = "List of additional principals to grant access to send to the Ingest SQS. This is required to allow STAC API SNS notifications (e.g. earth search's ingest SNS topic) to be able to publish SQS ingest messages to our stac-server for indexing."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "authorized_s3_arns" {
  description = "List of S3 bucket ARNs to give GetObject permissions to"
  type        = list(string)
  default     = []
}

variable "opensearch_cluster_dedicated_master_count" {
  description = "Number of dedicated main nodes in the cluster."
  type        = number
  default     = 3
}

variable "deploy_stac_server_opensearch_serverless" {
  type        = bool
  default     = false
  description = "Deploy FilmDrop Stac-Server with OpenSearch Serverless. If False, Stac-server will be deployed with a classic OpenSearch domain."
}

variable "deploy_stac_server_outside_vpc" {
  type        = bool
  default     = false
  description = "Deploy FilmDrop Stac-Server resources, including OpenSearch outside VPC. Defaults to false. If False, Stac-server resources will be deployed within the vpc."
}

variable "stac_api_url" {
  description = "When the STAC_API_URL env var is set, the item/message will have the self link set to the ingested items URL in the API; if not, the self link points to the copy of it in s3."
  type        = string
  default     = ""
}

variable "cors_origin" {
  description = ""
  type        = string
  default     = "*"
}

variable "cors_credentials" {
  description = ""
  type        = bool
  default     = false
}

variable "cors_methods" {
  description = ""
  type        = string
  default     = ""
}

variable "cors_headers" {
  description = ""
  type        = string
  default     = ""
}

variable "domain_alias" {
  description = "Custom domain alias for private API Gateway endpoint"
  type        = string
  default     = ""
}

variable "private_certificate_arn" {
  description = "Private Certificate ARN for custom domain alias of private API Gateway endpoint"
  type        = string
  default     = ""
}
