variable "environment" {
  description = "Project environment."
  type        = string
  validation {
    condition     = length(var.environment) <= 10
    error_message = "The environment value must be 10 or fewer characters."
  }
}

variable "project_name" {
  description = "Project Name"
  type        = string
  validation {
    condition     = length(var.project_name) <= 10
    error_message = "The project_name value must be a 10 or fewer characters."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID for the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
}

variable "private_subnet_ids" {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "security_group_id" {
  description = "Default security groups in the FilmDrop vpc"
  type        = string
}

variable "stac_server_inputs" {
  description = "Inputs for stac-server FilmDrop deployment."
  type = object({
    app_name                                    = string
    version                                     = string
    deploy_cloudfront                           = bool
    domain_alias                                = string
    enable_transactions_extension               = bool
    collection_to_index_mappings                = string
    opensearch_cluster_instance_type            = string
    opensearch_cluster_instance_count           = number
    opensearch_cluster_dedicated_master_enabled = bool
    opensearch_cluster_dedicated_master_type    = string
    opensearch_cluster_dedicated_master_count   = number
    ingest_sns_topic_arns                       = list(string)
    additional_ingest_sqs_senders_arns          = list(string)
    opensearch_ebs_volume_size                  = number
    stac_server_and_titiler_s3_arns             = list(string)
    web_acl_id                                  = string
    cf_function_name                            = string
    cf_function_runtime                         = string
    cf_function_code_path                       = string
    attach_cf_function                          = bool
    cf_function_event_type                      = string
    create_cf_function                          = bool
    create_cf_basicauth_function                = bool
    ingest = object({
      source_catalog_url               = string
      destination_collections_list     = string
      destination_collections_min_lat  = number
      destination_collections_min_long = number
      destination_collections_max_lat  = number
      destination_collections_max_long = number
      date_start                       = string
      date_end                         = string
      include_historical_ingest        = bool
      source_sns_arn                   = string
      include_ongoing_ingest           = bool
    })
  })
  default = {
    app_name                                    = "stac_server"
    version                                     = "v3.5.0"
    deploy_cloudfront                           = true
    domain_alias                                = ""
    enable_transactions_extension               = false
    collection_to_index_mappings                = ""
    opensearch_cluster_instance_type            = "t3.small.search"
    opensearch_cluster_instance_count           = 3
    opensearch_cluster_dedicated_master_enabled = true
    opensearch_cluster_dedicated_master_type    = "t3.small.search"
    opensearch_cluster_dedicated_master_count   = 3
    ingest_sns_topic_arns                       = []
    additional_ingest_sqs_senders_arns          = []
    opensearch_ebs_volume_size                  = 35
    stac_server_and_titiler_s3_arns             = []
    web_acl_id                                  = ""
    cf_function_name                            = ""
    cf_function_runtime                         = "cloudfront-js-2.0"
    cf_function_code_path                       = ""
    attach_cf_function                          = false
    cf_function_event_type                      = "viewer-request"
    create_cf_function                          = false
    create_cf_basicauth_function                = false
    ingest = {
      source_catalog_url               = ""
      destination_collections_list     = ""
      destination_collections_min_lat  = -90
      destination_collections_min_long = -180
      destination_collections_max_lat  = 90
      destination_collections_max_long = 180
      date_start                       = ""
      date_end                         = ""
      include_historical_ingest        = false
      source_sns_arn                   = ""
      include_ongoing_ingest           = false
    }
  }
}

variable "s3_logs_archive_bucket" {
  description = "Name of existing FilmDrop Archive Bucket"
  type        = string
}

variable "domain_zone" {
  description = "The DNS zone id to add the record to."
  type        = string
}

variable "create_log_bucket" {
  description = "Whether to create [true/false] logging bucket for Cloudfront Distribution"
  type        = bool
  default     = true
}

variable "log_bucket_name" {
  description = "Name of existing CloudFront Distribution Logging bucket"
  type        = string
  default     = ""
}

variable "log_bucket_domain_name" {
  description = "Domain Name of existing CloudFront Distribution Logging bucket"
  type        = string
  default     = ""
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
