variable environment {
  description = "Project environment."
  type        = string
  validation {
    condition     = length(var.environment) <= 10
    error_message = "The environment value must be 10 or fewer characters."
  }
}

variable project_name {
  description = "Project Name"
  type        = string
  validation {
    condition     = length(var.project_name) <= 10
    error_message = "The project_name value must be a 10 or fewer characters."
  }
}

variable vpc_id {
  type        = string
  description = "ID for the VPC"
}

variable vpc_cidr {
  type        = string
  description = "CIDR for the VPC"
}

variable private_subnet_ids {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "security_group_id" {
  description = "Default security groups in the FilmDrop vpc"
  type        = string
}

variable stac_server_inputs {
  description = "Inputs for stac-server FilmDrop deployment."
  type        = object({
    app_name                                      = string
    version                                       = string
    domain_alias                                  = string
    enable_transactions_extension                 = bool
    collection_to_index_mappings                  = string
    opensearch_cluster_instance_type              = string
    opensearch_cluster_instance_count             = number
    opensearch_cluster_dedicated_master_enabled   = bool
    opensearch_cluster_dedicated_master_type      = string
    opensearch_cluster_dedicated_master_count     = number
    ingest_sns_topic_arns                         = list(string)
    opensearch_ebs_volume_size                    = number
    stac_server_and_titiler_s3_arns               = list(string)
    web_acl_id                                    = string
  })
  default       = {
    app_name                                      = "stac_server"
    version                                       = "v2.2.3"
    domain_alias                                  = ""
    enable_transactions_extension                 = false
    collection_to_index_mappings                  = ""
    opensearch_cluster_instance_type              = "t3.small.search"
    opensearch_cluster_instance_count             = 3
    opensearch_cluster_dedicated_master_enabled   = true
    opensearch_cluster_dedicated_master_type      = "t3.small.search"
    opensearch_cluster_dedicated_master_count     = 3
    ingest_sns_topic_arns                         = []
    opensearch_ebs_volume_size                    = 35
    stac_server_and_titiler_s3_arns               = []
    web_acl_id                                    = ""
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