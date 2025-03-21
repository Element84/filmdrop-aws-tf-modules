variable "vpc_cidr_range" {
  description = "CIDR Range for FilmDrop vpc"
  type        = string
}

variable "vpc_private_subnet_ids" {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "vpc_private_subnet_azs" {
  description = "List of private subnet AZs in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "vpc_public_subnet_ids" {
  description = "List of public subnet ids in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "vpc_public_subnet_azs" {
  description = "List of public subnet AZs in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "analytics_main_node_azs" {
  description = "List of AZs for the Analytics main nodes within the Public Subnet"
  type        = list(string)
  default     = []
}

variable "analytics_worker_node_azs" {
  description = "List of AZs for the Analytics worker nodes within the Private Subnet"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "FilmDrop VPC ID"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes Cluster version"
  type        = string
  default     = "1.32"
}

variable "kubernetes_autoscaler_version" {
  description = "Kubernetes Cluster Autoscaler version"
  type        = string
  default     = "v1.32.0"
}

variable "jupyterhub_image_version" {
  description = "FilmDrop JupyterHub Image Docker Version"
  type        = string
  default     = "latest"
}

variable "jupyterhub_elb_acm_cert_arn" {
  description = "FilmDrop JupyterHub EKS ELB ACM Cert"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Project environment"
  type        = string
}
variable "jupyterhub_nodegroup_instance_types" {
  description = "Jupyterhub Nodegroup Instance Types"
  type        = list(string)
  default     = ["m5.large", "m5.xlarge"]
}

variable "jupyterhub_nodegroup_min_size" {
  description = "Jupyterhub Nodegroup Min Cluster Size"
  type        = number
  default     = 1
}

variable "jupyterhub_nodegroup_max_size" {
  description = "Jupyterhub Nodegroup Max Cluster Size"
  type        = number
  default     = 10
}

variable "daskhub_nodegroup_instance_types" {
  description = "Daskhub Nodegroup Instance Types"
  type        = list(string)
  default     = ["m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge"]
}

variable "jupyterhub_admin_username_list" {
  description = "FilmDrop Analytics Admin Users List"
  type        = list(string)
  default     = ["admin"]
}

variable "daskhub_nodegroup_min_size" {
  description = "Daskhub Nodegroup Min Cluster Size"
  type        = number
  default     = 1
}

variable "daskhub_nodegroup_max_size" {
  description = "Daskhub Nodegroup Max Cluster Size"
  type        = number
  default     = 30
}

variable "zone_id" {
  description = "The DNS zone id to add the record to."
  type        = string
  default     = ""
}

variable "domain_alias" {
  description = "Alternate alias for Jupyter Load Balancer"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID for Analytics cluster"
  type        = string
  default     = ""
}

variable "daskhub_stage" {
  description = "The stage name for daskhub"
  type        = string
}

variable "domain_param_name" {
  description = "Domain Parameter Name"
  type        = string
  default     = ""
}

variable "analytics_cleanup_enabled" {
  description = "Deploy FilmDrop Analytics cleanup functionality."
  type        = bool
  default     = false
}

variable "analytics_asg_min_capacity" {
  description = "FilmDrop Analytics ASG min capacity"
  type        = number
  default     = 1
}

variable "analytics_node_limit" {
  description = "FilmDrop Analytics node limit for normal usage"
  type        = number
  default     = 4
}

variable "analytics_notifications_schedule_expressions" {
  description = "FilmDrop Analytics notification scheduled expressions"
  type        = list(string)
  default     = ["cron(0 14 * * ? *)", "cron(0 22 * * ? *)"]
}

variable "analytics_cleanup_schedule_expressions" {
  description = "FilmDrop Analytics cleanup scheduled expressions"
  type        = list(string)
  default     = ["cron(0 5 * * ? *)"]
}

locals {
  kubernetes_cluster_name = "fd-analytics-${var.project_name}-${var.environment}"
}
