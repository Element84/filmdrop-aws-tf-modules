variable "environment" {
  description = "Project environment."
  type        = string
  validation {
    condition     = length(var.environment) <= 5
    error_message = "The environment value must be 5 or fewer characters."
  }
}

variable "project_name" {
  description = "Project Name"
  type        = string
  validation {
    condition     = length(var.project_name) <= 8
    error_message = "The project_name value must be a 8 or fewer characters."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID for the VPC"
  default     = ""
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
  default     = ""
}

variable "public_subnets_az_to_id_map" {
  type        = map(any)
  description = "Map with the availability zone to the id for public subnets"
  default     = {}
}

variable "private_subnets_az_to_id_map" {
  type        = map(any)
  description = "Map with the availability zone to the id for private subnets"
  default     = {}
}

variable "security_group_id" {
  type        = string
  description = "ID for the Security Group in the FilmDrop VPC"
  default     = ""
}

variable "sns_topics_map" {
  type    = map(any)
  default = {}
}

variable "cloudwatch_warning_alarms_map" {
  type    = map(any)
  default = {}
}

variable "cloudwatch_critical_alarms_map" {
  type    = map(any)
  default = {}
}

variable "sns_warning_subscriptions_map" {
  type    = map(any)
  default = {}
}

variable "sns_critical_subscriptions_map" {
  type    = map(any)
  default = {}
}

variable "s3_access_log_bucket" {
  description = "FilmDrop S3 Access Log Bucket Name"
  type        = string
  default     = ""
}

variable "s3_logs_archive_bucket" {
  description = "FilmDrop S3 Archive Log Bucket Name"
  type        = string
  default     = ""
}

variable "domain_zone" {
  description = "The DNS zone id to add the record to."
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

variable "titiler_inputs" {
  description = "Inputs for titiler FilmDrop deployment."
  type = object({
    app_name                        = string
    domain_alias                    = string
    mosaic_titiler_release_tag      = string
    stac_server_and_titiler_s3_arns = list(string)
    mosaic_titiler_waf_allowed_url  = string
    mosaic_titiler_host_header      = string
    web_acl_id                      = string
    cf_function_name                = string
    cf_function_runtime             = string
    cf_function_code_path           = string
    attach_cf_function              = bool
    cf_function_event_type          = string
    create_cf_function              = bool
    create_cf_basicauth_function    = bool
  })
  default = {
    app_name                        = "titiler"
    domain_alias                    = ""
    mosaic_titiler_release_tag      = "v0.14.0-1.0.4"
    stac_server_and_titiler_s3_arns = []
    mosaic_titiler_waf_allowed_url  = ""
    mosaic_titiler_host_header      = ""
    web_acl_id                      = ""
    cf_function_name                = ""
    cf_function_runtime             = "cloudfront-js-2.0"
    cf_function_code_path           = ""
    attach_cf_function              = false
    cf_function_event_type          = "viewer-request"
    create_cf_function              = false
    create_cf_basicauth_function    = false
  }
}

variable "analytics_inputs" {
  description = "Inputs for analytics FilmDrop deployment."
  type = object({
    app_name                     = string
    domain_alias                 = string
    jupyterhub_elb_acm_cert_arn  = string
    jupyterhub_elb_domain_alias  = string
    create_credentials           = bool
    cf_function_name             = string
    cf_function_runtime          = string
    cf_function_code_path        = string
    attach_cf_function           = bool
    cf_function_event_type       = string
    create_cf_function           = bool
    create_cf_basicauth_function = bool

  })
  default = {
    app_name                     = "analytics"
    domain_alias                 = ""
    jupyterhub_elb_acm_cert_arn  = ""
    jupyterhub_elb_domain_alias  = ""
    create_credentials           = true
    cf_function_name             = ""
    cf_function_runtime          = "cloudfront-js-2.0"
    cf_function_code_path        = ""
    attach_cf_function           = false
    cf_function_event_type       = "viewer-request"
    create_cf_function           = false
    create_cf_basicauth_function = false
  }
}

variable "console_ui_inputs" {
  description = "Inputs for console-ui FilmDrop deployment."
  type = object({
    app_name     = string
    domain_alias = string
    custom_error_response = list(object({
      error_caching_min_ttl = string
      error_code            = string
      response_code         = string
      response_page_path    = string
    }))
    filmdrop_ui_release          = string
    filmdrop_ui_config_file      = string
    filmdrop_ui_logo_file        = string
    filmdrop_ui_logo             = string
    cf_function_name             = string
    cf_function_runtime          = string
    cf_function_code_path        = string
    attach_cf_function           = bool
    cf_function_event_type       = string
    create_cf_function           = bool
    create_cf_basicauth_function = bool
  })
  default = {
    app_name     = "console"
    domain_alias = ""
    custom_error_response = [
      {
        error_caching_min_ttl = "10"
        error_code            = "404"
        response_code         = "200"
        response_page_path    = "/"
      }
    ]
    filmdrop_ui_release          = "v5.0.0"
    filmdrop_ui_config_file      = ""
    filmdrop_ui_logo_file        = ""
    filmdrop_ui_logo             = "bm9uZQo=" # Base64: 'none'
    cf_function_name             = ""
    cf_function_runtime          = "cloudfront-js-2.0"
    cf_function_code_path        = ""
    attach_cf_function           = false
    cf_function_event_type       = "viewer-request"
    create_cf_function           = false
    create_cf_basicauth_function = false
  }
}

variable "cirrus_dashboard_inputs" {
  description = "Inputs for cirrus dashboard FilmDrop deployment."
  type = object({
    app_name     = string
    domain_alias = string
    custom_error_response = list(object({
      error_caching_min_ttl = string
      error_code            = string
      response_code         = string
      response_page_path    = string
    }))
    cirrus_api_endpoint_base     = string
    cirrus_dashboard_release     = string
    cf_function_name             = string
    cf_function_runtime          = string
    cf_function_code_path        = string
    attach_cf_function           = bool
    cf_function_event_type       = string
    create_cf_function           = bool
    create_cf_basicauth_function = bool
  })
  default = {
    app_name     = "dashboard"
    domain_alias = ""
    custom_error_response = [
      {
        error_caching_min_ttl = "10"
        error_code            = "404"
        response_code         = "200"
        response_page_path    = "/"
      }
    ]
    cirrus_api_endpoint_base     = ""
    cirrus_dashboard_release     = "v0.5.1"
    cf_function_name             = ""
    cf_function_runtime          = "cloudfront-js-2.0"
    cf_function_code_path        = ""
    attach_cf_function           = false
    cf_function_event_type       = "viewer-request"
    create_cf_function           = false
    create_cf_basicauth_function = false
  }
}

variable "deploy_vpc" {
  type        = bool
  default     = false
  description = "Deploy FilmDrop VPC stack"
}

variable "deploy_vpc_search" {
  type        = bool
  default     = true
  description = "Perform a FilmDrop VPC search"
}

variable "deploy_log_archive" {
  type        = bool
  default     = true
  description = "Deploy FilmDrop Log Archive Bucket"
}

variable "deploy_alarms" {
  type        = bool
  default     = false
  description = "Deploy FilmDrop Alarms stack"
}

variable "deploy_stac_server" {
  type        = bool
  default     = true
  description = "Deploy FilmDrop Stac-Server"
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

variable "deploy_analytics" {
  type        = bool
  default     = true
  description = "Deploy FilmDrop Analytics stack"
}

variable "deploy_titiler" {
  type        = bool
  default     = true
  description = "Deploy FilmDrop TiTiler stack"
}

variable "deploy_console_ui" {
  type        = bool
  default     = true
  description = "Deploy FilmDrop Console UI stack"
}

variable "deploy_cirrus_dashboard" {
  type        = bool
  default     = true
  description = "Deploy FilmDrop Cirrus Dashboard stack"
}

variable "deploy_local_stac_server_artifacts" {
  description = "Deploy STAC Server artifacts for local deploy"
  type        = bool
  default     = true
}

variable "deploy_sample_data_bucket" {
  type        = bool
  default     = false
  description = "Deploy FilmDrop STAC sample data bucket"
}

variable "project_sample_data_bucket_name" {
  description = "STAC sample data bucket name"
  type        = string
  default     = ""
}
