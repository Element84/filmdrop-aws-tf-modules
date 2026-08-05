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
    version                                     = optional(string)
    lambda_zip_filepath                         = optional(string)
    stac_id                                     = optional(string)
    stac_title                                  = optional(string)
    stac_description                            = optional(string)
    web_acl_id                                  = string
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
    opensearch_cluster_zone_awareness_enabled   = bool
    opensearch_cluster_dedicated_master_type    = string
    opensearch_cluster_dedicated_master_count   = number
    opensearch_cluster_availability_zone_count  = number
    opensearch_ebs_volume_size                  = number
    opensearch_logs = optional(object({
      ES_APPLICATION_LOGS = optional(object({
        enabled                     = bool
        retention_in_days           = number
        deletion_protection_enabled = optional(bool, false)
      }))
      INDEX_SLOW_LOGS = optional(object({
        enabled                     = bool
        retention_in_days           = number
        deletion_protection_enabled = optional(bool, false)
      }))
      SEARCH_SLOW_LOGS = optional(object({
        enabled                     = bool
        retention_in_days           = number
        deletion_protection_enabled = optional(bool, false)
      }))
      AUDIT_LOGS = optional(object({
        enabled                     = bool
        retention_in_days           = number
        deletion_protection_enabled = bool
      }))
    }), {})
    opensearch_override_main_response_version = bool
    ingest_sns_topic_arns                     = list(string)
    additional_ingest_sqs_senders_arns        = list(string)
    cors_origin                               = string
    cors_credentials                          = bool
    cors_methods                              = string
    cors_headers                              = string
    authorized_s3_arns                        = list(string)
    api_rest_type                             = string
    # default 0 required here so that this property is not explicitly null, if not provided
    api_provisioned_concurrency   = optional(number, 0)
    api_method_authorization_type = optional(string)
    # Public URL configuration. The API always exists at API Gateway's default
    # URL, which ends in the stage:
    #   "https://<api-id>.execute-api.<region>.amazonaws.com/<stage>/"
    # These fields control what, if anything, sits in front of that URL:
    #
    #   deploy_cloudfront = true
    #     CloudFront in front. Serves the API at "https://<domain>/", where
    #     <domain> is domain_alias if set, else the default *.cloudfront.net
    #     name. Set stac_api_expose_stage_in_path = true to serve at
    #     "https://<domain>/<stage>/" instead.
    #
    #   deploy_cloudfront = false, domain_alias set
    #     API Gateway custom domain (requires api_rest_type = "PRIVATE" and
    #     private_certificate_arn). Always serves at "https://<domain_alias>/";
    #     stac_api_expose_stage_in_path = true fails validation.
    #
    #   deploy_cloudfront = false, no domain_alias
    #     Clients use the default URL directly; the stage is always in the
    #     path and stac_api_expose_stage_in_path has no effect.
    #
    # stac_api_stage names the API Gateway stage (no slash, e.g. "v2");
    # defaults to var.environment. Resource names always derive from
    # var.environment, never from the stage.
    #
    # stac_api_url overrides the public URL stac-server advertises in API
    # responses (landing-page and search links), normally derived from
    # domain_alias. Set it when clients reach the API through CloudFront's
    # auto-assigned *.cloudfront.net domain (deploy_cloudfront with no
    # domain_alias), which is only known after the first apply — e.g.
    # "https://d123abc.cloudfront.net/v2". Left unset with no domain_alias,
    # advertised links fall back to API Gateway's default URL and bypass
    # CloudFront.
    deploy_cloudfront                         = bool
    domain_alias                              = string
    stac_api_stage                            = optional(string)
    stac_api_expose_stage_in_path             = optional(bool, false)
    stac_api_url                              = optional(string)
    private_api_additional_security_group_ids = optional(list(string))
    private_certificate_arn                   = optional(string)
    vpce_private_dns_enabled                  = bool
    custom_vpce_id                            = optional(string)
    api_lambda = optional(object({
      handler               = optional(string)
      memory_mb             = optional(number)
      runtime               = optional(string)
      timeout_seconds       = optional(number)
      environment_variables = optional(map(string))
    }))
    ingest_lambda = optional(object({
      handler               = optional(string)
      memory_mb             = optional(number)
      runtime               = optional(string)
      timeout_seconds       = optional(number)
      environment_variables = optional(map(string))
    }))
    pre_hook_lambda = optional(object({
      handler               = optional(string)
      memory_mb             = optional(number)
      runtime               = optional(string)
      timeout_seconds       = optional(number)
      environment_variables = optional(map(string))
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
    stac_id                                     = "stac-server"
    stac_title                                  = "STAC API"
    stac_description                            = "A STAC API using stac-server"
    web_acl_id                                  = ""
    enable_transactions_extension               = false
    enable_collections_authx                    = false
    enable_filter_authx                         = false
    enable_response_compression                 = true
    items_max_limit                             = 100
    enable_ingest_action_truncate               = false
    collection_to_index_mappings                = ""
    opensearch_version                          = "OpenSearch_2.19"
    opensearch_cluster_instance_type            = "t3.small.search"
    opensearch_cluster_instance_count           = 3
    opensearch_cluster_dedicated_master_enabled = true
    opensearch_cluster_zone_awareness_enabled   = true
    opensearch_cluster_dedicated_master_type    = "t3.small.search"
    opensearch_cluster_dedicated_master_count   = 3
    opensearch_cluster_availability_zone_count  = 3
    opensearch_ebs_volume_size                  = 35
    opensearch_override_main_response_version   = null
    ingest_sns_topic_arns                       = []
    additional_ingest_sqs_senders_arns          = []
    cors_origin                                 = "*"
    cors_credentials                            = false
    cors_methods                                = ""
    cors_headers                                = ""
    authorized_s3_arns                          = []
    api_rest_type                               = "EDGE"
    api_method_authorization_type               = "NONE"
    deploy_cloudfront                           = true
    domain_alias                                = ""
    private_api_additional_security_group_ids   = null
    api_lambda                                  = null
    ingest_lambda                               = null
    pre_hook_lambda                             = null
    private_certificate_arn                     = ""
    vpce_private_dns_enabled                    = false
    custom_vpce_id                              = null
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
  validation {
    condition = !(
      var.stac_server_inputs.stac_api_expose_stage_in_path
      && var.stac_server_inputs.domain_alias != ""
      && !var.stac_server_inputs.deploy_cloudfront
    )
    error_message = "stac_api_expose_stage_in_path requires deploy_cloudfront: an API Gateway custom domain (domain_alias without CloudFront) can only serve the API at the domain root."
  }
  validation {
    condition = (
      var.stac_server_inputs.domain_alias == ""
      || var.stac_server_inputs.deploy_cloudfront
      || (
        var.stac_server_inputs.api_rest_type == "PRIVATE"
        && coalesce(var.stac_server_inputs.private_certificate_arn, "") != ""
      )
    )
    error_message = "domain_alias without deploy_cloudfront is an API Gateway custom domain, which requires api_rest_type = \"PRIVATE\" and private_certificate_arn."
  }
  validation {
    condition = (
      var.stac_server_inputs.stac_api_stage == null
      || can(regex("^[A-Za-z0-9_-]+$", var.stac_server_inputs.stac_api_stage))
    )
    error_message = "stac_api_stage is an API Gateway stage name and URL path segment; it may contain only letters, numbers, hyphens, and underscores."
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
