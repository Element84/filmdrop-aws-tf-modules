variable "environment" {
  description = "Project environment."
  type        = string
  validation {
    condition     = length(var.environment) <= 7
    error_message = "The environment value must be 7 or fewer characters."
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
  description = "Map with the availability zone to the subnet-id for public subnets. If deploy_vpc = true, then specify the map with az => subnet-cidr-range instead."
  default     = {}
}

variable "private_subnets_az_to_id_map" {
  type        = map(any)
  description = "Map with the availability zone to the subnet-id for private subnets. If deploy_vpc = true, then specify the map with az => subnet-cidr-range instead."
  default     = {}
}

variable "security_group_id" {
  type        = string
  description = "ID for the Security Group in the FilmDrop VPC"
  default     = ""
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
    cors_origin                                 = ""
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

variable "titiler_inputs" {
  description = "Inputs for titiler FilmDrop deployment."
  type = object({
    app_name                                  = string
    domain_alias                              = string
    deploy_cloudfront                         = bool
    version                                   = string
    authorized_s3_arns                        = list(string)
    mosaic_titiler_waf_allowed_url            = string
    mosaic_titiler_host_header                = string
    mosaic_tile_timeout                       = number
    web_acl_id                                = string
    is_private_endpoint                       = optional(bool)
    api_method_authorization_type             = optional(string)
    private_certificate_arn                   = optional(string)
    private_api_additional_security_group_ids = optional(list(string))
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
  })
  default = {
    app_name                                  = "titiler"
    domain_alias                              = ""
    deploy_cloudfront                         = true
    version                                   = "v0.14.0-1.0.5"
    authorized_s3_arns                        = []
    mosaic_titiler_waf_allowed_url            = ""
    mosaic_titiler_host_header                = ""
    mosaic_tile_timeout                       = 30
    web_acl_id                                = ""
    is_private_endpoint                       = false
    api_method_authorization_type             = "NONE"
    private_certificate_arn                   = ""
    private_api_additional_security_group_ids = null
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
  }
}

variable "analytics_inputs" {
  description = "Inputs for analytics FilmDrop deployment."
  type = object({
    app_name                    = string
    domain_alias                = string
    web_acl_id                  = string
    jupyterhub_elb_acm_cert_arn = string
    jupyterhub_elb_domain_alias = string
    create_credentials          = bool
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
    cleanup = object({
      enabled                            = bool
      asg_min_capacity                   = number
      analytics_node_limit               = number
      notifications_schedule_expressions = list(string)
      cleanup_schedule_expressions       = list(string)
    })
    eks = object({
      cluster_version    = string
      autoscaler_version = string
    })
  })
  default = {
    app_name                    = "analytics"
    domain_alias                = ""
    web_acl_id                  = ""
    jupyterhub_elb_acm_cert_arn = ""
    jupyterhub_elb_domain_alias = ""
    create_credentials          = true
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
    cleanup = {
      enabled                            = false
      asg_min_capacity                   = 1
      analytics_node_limit               = 4
      notifications_schedule_expressions = []
      cleanup_schedule_expressions       = []
    }
    eks = {
      cluster_version    = "1.32"
      autoscaler_version = "v1.32.0"
    }
  }
}

variable "console_ui_inputs" {
  description = "Inputs for console-ui FilmDrop deployment."
  type = object({
    app_name          = string
    domain_alias      = string
    deploy_cloudfront = bool
    deploy_s3_bucket  = optional(bool)
    external_content_bucket = optional(object({
      external_content_website_bucket_name         = optional(string)
      external_content_bucket_regional_domain_name = optional(string)
    }))
    web_acl_id = string
    custom_error_response = list(object({
      error_caching_min_ttl = string
      error_code            = string
      response_code         = string
      response_page_path    = string
    }))
    version                 = string
    filmdrop_ui_config_file = string
    filmdrop_ui_logo_file   = string
    filmdrop_ui_logo        = string
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
  })
  default = {
    app_name          = "console"
    domain_alias      = ""
    deploy_cloudfront = true
    deploy_s3_bucket  = true
    external_content_bucket = {
      external_content_website_bucket_name         = ""
      external_content_bucket_regional_domain_name = ""
    }
    web_acl_id = ""
    custom_error_response = [
      {
        error_caching_min_ttl = "10"
        error_code            = "404"
        response_code         = "200"
        response_page_path    = "/"
      }
    ]
    version                 = "v5.3.0"
    filmdrop_ui_config_file = "./profiles/console-ui/default-config/config.dev.json"
    filmdrop_ui_logo_file   = "./profiles/console-ui/default-config/logo.png"
    filmdrop_ui_logo        = "bm9uZQo=" # Base64: 'none'
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
  }
}

variable "cirrus_inputs" {
  description = "Inputs for FilmDrop Cirrus deployment"
  type = object({
    data_bucket                               = string
    payload_bucket                            = string
    log_level                                 = string
    api_rest_type                             = string
    private_api_additional_security_group_ids = optional(list(string))
    deploy_alarms                             = bool
    private_certificate_arn                   = optional(string)
    domain_alias                              = optional(string)
    custom_alarms = object({
      warning  = map(any)
      critical = map(any)
    })
    process = object({
      sqs_timeout           = number
      sqs_max_receive_count = number
    })
    state = object({
      timestream_magnetic_store_retention_period_in_days = number
      timestream_memory_store_retention_period_in_hours  = number
    })
    lambda_version      = optional(string)
    lambda_zip_filepath = optional(string)
    api_lambda = object({
      timeout = number
      memory  = number
    })
    process_lambda = object({
      timeout              = number
      memory               = number
      reserved_concurrency = number
    })
    update_state_lambda = object({
      timeout = number
      memory  = number
    })
    pre_batch_lambda = object({
      timeout = number
      memory  = number
    })
    post_batch_lambda = object({
      timeout = number
      memory  = number
    })
    task_batch_compute_definitions_dir           = optional(string)
    task_batch_compute_definitions_variables     = optional(map(map(string)))
    task_batch_compute_definitions_variables_ssm = optional(map(map(string)))
    task_definitions_dir                         = optional(string)
    task_definitions_variables                   = optional(map(map(string)))
    task_definitions_variables_ssm               = optional(map(map(string)))
    workflow_definitions_dir                     = optional(string)
    workflow_definitions_variables               = optional(map(map(string)))
    workflow_definitions_variables_ssm           = optional(map(map(string)))
    cirrus_cli_iam_role_trust_principal          = optional(list(string))
  })
  default = {
    data_bucket                               = "cirrus-data-bucket-name"
    payload_bucket                            = "cirrus-payload-bucket-name"
    log_level                                 = "INFO"
    api_rest_type                             = "EDGE"
    private_api_additional_security_group_ids = null
    deploy_alarms                             = true
    private_certificate_arn                   = ""
    domain_alias                              = ""
    custom_alarms = {
      warning  = {}
      critical = {}
    }
    process = {
      sqs_timeout           = 180
      sqs_max_receive_count = 5
    }
    state = {
      timestream_magnetic_store_retention_period_in_days = 93
      timestream_memory_store_retention_period_in_hours  = 24
    }
    lambda_version      = null
    lambda_zip_filepath = null
    api_lambda = {
      timeout = 10
      memory  = 128
    }
    process_lambda = {
      timeout              = 10
      memory               = 128
      reserved_concurrency = 16
    }
    update_state_lambda = {
      timeout = 15
      memory  = 128
    }
    pre_batch_lambda = {
      timeout = 15
      memory  = 128
    }
    post_batch_lambda = {
      timeout = 15
      memory  = 128
    }
    task_batch_compute_definitions_dir           = null
    task_batch_compute_definitions_variables     = null
    task_batch_compute_definitions_variables_ssm = null
    task_definitions_dir                         = null
    task_definitions_variables                   = null
    task_definitions_variables_ssm               = null
    workflow_definitions_dir                     = null
    workflow_definitions_variables               = null
    workflow_definitions_variables_ssm           = null
    cirrus_cli_iam_role_trust_principal          = null
  }
}

variable "cirrus_dashboard_inputs" {
  description = "Inputs for cirrus dashboard FilmDrop deployment."
  type = object({
    app_name          = string
    domain_alias      = string
    deploy_cloudfront = bool
    deploy_s3_bucket  = optional(bool)
    external_content_bucket = optional(object({
      external_content_website_bucket_name         = optional(string)
      external_content_bucket_regional_domain_name = optional(string)
    }))
    web_acl_id           = string
    version              = string
    cirrus_api_endpoint  = string
    metrics_api_endpoint = string
    custom_error_response = list(object({
      error_caching_min_ttl = string
      error_code            = string
      response_code         = string
      response_page_path    = string
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
  })
  default = {
    app_name          = "dashboard"
    domain_alias      = ""
    deploy_cloudfront = true
    deploy_s3_bucket  = true
    external_content_bucket = {
      external_content_website_bucket_name         = ""
      external_content_bucket_regional_domain_name = ""
    }
    web_acl_id           = ""
    version              = "v0.5.1"
    cirrus_api_endpoint  = ""
    metrics_api_endpoint = ""

    custom_error_response = [
      {
        error_caching_min_ttl = "10"
        error_code            = "404"
        response_code         = "200"
        response_page_path    = "/"
      }
    ]
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

variable "deploy_cirrus" {
  type        = bool
  default     = true
  description = "Deploy FilmDrop Cirrus stack"
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

variable "deploy_waf_rule" {
  description = "Deploy FilmDrop WAF rule"
  type        = bool
  default     = true
}

variable "ip_blocklist" {
  description = "List of ip cidr ranges to block access to. "
  type        = set(string)
  default     = []
}

variable "whitelist_ips" {
  description = "List of ips to filter access for."
  type        = set(string)
  default     = []
}

variable "ext_web_acl_id" {
  description = "The id of the external WAF resource to attach to the FilmDrop CloudFront Endpoints."
  type        = string
  default     = ""
}
