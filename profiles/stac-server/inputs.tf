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
    stac_id                                     = optional(string)
    stac_title                                  = optional(string)
    stac_description                            = optional(string)
    deploy_cloudfront                           = bool
    web_acl_id                                  = string
    domain_alias                                = string
    enable_transactions_extension               = bool
    enable_collections_authx                    = bool
    enable_filter_authx                         = bool
    enable_response_compression                 = bool
    items_max_limit                             = number
    enable_ingest_action_truncate               = bool
    collection_to_index_mappings                = string
    opensearch_version                          = optional(string)
    opensearch_cluster_instance_type            = string
    opensearch_cluster_instance_count           = number
    opensearch_cluster_dedicated_master_enabled = bool
    opensearch_cluster_dedicated_master_type    = string
    opensearch_cluster_dedicated_master_count   = number
    opensearch_cluster_availability_zone_count  = number
    opensearch_ebs_volume_size                  = number
    ingest_sns_topic_arns                       = list(string)
    additional_ingest_sqs_senders_arns          = list(string)
    cors_origin                                 = string
    cors_credentials                            = bool
    cors_methods                                = string
    cors_headers                                = string
    authorized_s3_arns                          = list(string)
    api_rest_type                               = string
    api_method_authorization_type               = optional(string)
    private_api_additional_security_group_ids   = optional(list(string))
    private_certificate_arn                     = optional(string)
    api_lambda = optional(object({
      handler         = optional(string)
      memory_mb       = optional(number)
      runtime         = optional(string)
      timeout_seconds = optional(number)
      zip_filepath    = optional(string)
    }))
    ingest_lambda = optional(object({
      handler         = optional(string)
      memory_mb       = optional(number)
      runtime         = optional(string)
      timeout_seconds = optional(number)
      zip_filepath    = optional(string)
    }))
    pre_hook_lambda = optional(object({
      handler         = optional(string)
      memory_mb       = optional(number)
      runtime         = optional(string)
      timeout_seconds = optional(number)
      zip_filepath    = optional(string)
    }))
    auth_function = object({
      cf_function_name             = string
      cf_function_runtime          = string
      cf_function_code_path        = string
      attach_cf_function           = bool
      cf_function_event_type       = string
      create_cf_function           = bool
      create_cf_basicauth_function = bool
      cf_function_arn              = string
    })
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
    version                                     = "v3.10.0"
    stac_id                                     = "stac-server"
    stac_title                                  = "STAC API"
    stac_description                            = "A STAC API using stac-server"
    deploy_cloudfront                           = true
    web_acl_id                                  = ""
    domain_alias                                = ""
    enable_transactions_extension               = false
    enable_collections_authx                    = false
    enable_filter_authx                         = false
    enable_response_compression                 = true
    items_max_limit                             = 100
    enable_ingest_action_truncate               = false
    collection_to_index_mappings                = ""
    opensearch_version                          = "OpenSearch_2.17"
    opensearch_cluster_instance_type            = "t3.small.search"
    opensearch_cluster_instance_count           = 3
    opensearch_cluster_dedicated_master_enabled = true
    opensearch_cluster_dedicated_master_type    = "t3.small.search"
    opensearch_cluster_dedicated_master_count   = 3
    opensearch_cluster_availability_zone_count  = 3
    opensearch_ebs_volume_size                  = 35
    ingest_sns_topic_arns                       = []
    additional_ingest_sqs_senders_arns          = []
    cors_origin                                 = "*"
    cors_credentials                            = false
    cors_methods                                = ""
    cors_headers                                = ""
    authorized_s3_arns                          = []
    api_rest_type                               = "EDGE"
    api_method_authorization_type               = "NONE"
    private_api_additional_security_group_ids   = null
    api_lambda                                  = null
    ingest_lambda                               = null
    pre_hook_lambda                             = null
    private_certificate_arn                     = ""
    auth_function = {
      cf_function_name             = ""
      cf_function_runtime          = "cloudfront-js-2.0"
      cf_function_code_path        = ""
      attach_cf_function           = false
      cf_function_event_type       = "viewer-request"
      create_cf_function           = false
      create_cf_basicauth_function = false
      cf_function_arn              = ""
    }
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

variable "fd_web_acl_id" {
  description = "The id of the FilmDrop WAF resource."
  type        = string
  default     = ""
}
