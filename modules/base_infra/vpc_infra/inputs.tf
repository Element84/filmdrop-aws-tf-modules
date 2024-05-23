variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Project environment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for the new VPC"
  type        = string
}

variable "archive_log_bucket_name" {
  description = "FilmDrop S3 Archive Log bucket name"
  type        = string
}

variable "max_aggregation_interval" {
  description = "The maximum interval of time in seconds during which a flow of packets is captured and aggregated into a flow log record."
  type        = number
  default     = 600
}

variable "log_format" {
  description = "The fields to include in the flow log record, in the order in which they should appear."
  type        = string
  default     = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${instance-id} $${pkt-srcaddr} $${pkt-dstaddr} $${az-id} $${tcp-flags} $${flow-direction} $${traffic-path}"
}

variable "traffic_type" {
  description = "The type of traffic to capture."
  type        = string
  default     = "ALL"
}

variable "public_subnets_az_to_id_map" {
  description = "Map with the availability zone to the subnet-id for public subnets. If deploy_vpc = true, then specify the map with az => subnet-cidr-range instead."
  type        = map(any)
}

variable "private_subnets_az_to_id_map" {
  description = "Map with the availability zone to the subnet-id for private subnets. If deploy_vpc = true, then specify the map with az => subnet-cidr-range instead."
  type        = map(any)
}

variable "dhcp_options_domain_name_servers" {
  description = "List of name servers to configure for the FilmDrop VPC."
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "gateway_endpoints_list" {
  description = "List of VPC Gateway Endpoints to create in the FilmDrop VPC."
  type        = list(string)
  default     = ["s3", "dynamodb"]
}

variable "interface_endpoints_list" {
  description = "List of VPC Interface Endpoints to create in the FilmDrop VPC."
  type        = list(string)
  default     = ["secretsmanager", "ec2", "sts"]
}

locals {
  name_prefix = "fd-${var.project_name}-${var.environment}"
}