variable "vpc_cidr_range" {
  description = "CIDR Range for FilmDrop vpc"
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

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "FilmDrop VPC ID"
}

variable "kubernetes_version" {
  description = "Kubernetes Cluster version"
  default     = "1.23"
}

variable "kubernetes_autoscaler_version" {
  description = "Kubernetes Cluster Autoscaler version"
  default     = "v1.25.0"
}

variable "kubernetes_cluster_name" {
  description = "Kubernetes Cluster name"
  default     = "filmdrop-analytics"
}

variable "filmdrop_daskhub_helm_name" {
  description = "FilmDrop DaskHub Helm Name"
  default     = "filmdrop-daskhub"
}

variable "filmdrop_analytics_jupyterhub_admin_credentials_secret" {
  description = "FilmDrop JupyterHub Admin Credetials Secret Manager Secret"
  default     = "filmdrop-analytics-admin-credentials"
}

variable "filmdrop_analytics_dask_secret_tokens" {
  description = "FilmDrop Secret holding Dask Tokens"
  default     = "filmdrop-analytics-dask-tokens"
}

variable "jupyterhub_image_repo" {
  description = "FilmDrop JupyterHub Image Docker Repository"
  default     = "element84inc/filmdrop-analytics"
}

variable "jupyterhub_image_version" {
  description = "FilmDrop JupyterHub Image Docker Version"
  default     = "2022.12.20"
}

variable "jupyterhub_elb_acm_cert_arn" {
  description = "FilmDrop JupyterHub EKS ELB ACM Cert"
}

variable "eks_endpoint_private_access" {
  description = "EKS Private Endpoint Access"
  default     = false
}

variable "eks_endpoint_public_access" {
  description = "EKS Public Access"
  default     = true
}

variable "account_owner" {
  description = "Organization owning the AWS Account"
}

variable "managed_resource" {
  description = "Organization owning the AWS Account"
}

variable "project_name" {
  description = "Project Name"
}

variable "environment" {
  description = "Project environment."
}

variable "jupyterhub_nodegroup_ebs_volumesize" {
  description = "Jupyterhub EBS Volume Size"
  default     = 80
}

variable "jupyterhub_nodegroup_ebs_iops" {
  description = "Jupyterhub EBS IOPS"
  default     = 3000
}

variable "jupyterhub_nodegroup_encrypted" {
  description = "Jupyterhub EBS Encrypted"
  default     = true
}

variable "jupyterhub_nodegroup_throughput" {
  description = "Jupyterhub EBS Throughput"
  default     = 125
}

variable "jupyterhub_nodegroup_volume_type" {
  description = "Jupyterhub EBS VolumeType"
  default     = "gp3"
}

variable "jupyterhub_nodegroup_http_tokens" {
  description = "Jupyterhub Metadata HTTP Tokens"
  default     = "optional"
}

variable "jupyterhub_nodegroup_http_put_response_hop_limit" {
  description = "Jupyterhub Metadata HTTP Put Response Hop Limit"
  default     = 2
}

variable "jupyterhub_nodegroup_name" {
  description = "Jupyterhub Nodegroup Name"
  default     = "main"
}

variable "jupyterhub_nodegroup_ami_type" {
  description = "Jupyterhub Nodegroup AMI Type"
  default     = "AL2_x86_64"
}

variable "jupyterhub_nodegroup_instance_types" {
  description = "Jupyterhub Nodegroup Instance Types"
  default     = ["m5.large", "m5.xlarge"]
}

variable "jupyterhub_nodegroup_capacity_type" {
  description = "Jupyterhub Nodegroup Capacity Type"
  default     = "ON_DEMAND"
}

variable "jupyterhub_nodegroup_min_size" {
  description = "Jupyterhub Nodegroup Min Cluster Size"
  default     = 1
}

variable "jupyterhub_nodegroup_max_size" {
  description = "Jupyterhub Nodegroup Max Cluster Size"
  default     = 10
}

variable "jupyterhub_nodegroup_desired_size" {
  description = "Jupyterhub Nodegroup Desired Cluster Size"
  default     = 1
}

variable "daskhub_nodegroup_ebs_volumesize" {
  description = "Daskhub EBS Volume Size"
  default     = 80
}

variable "daskhub_nodegroup_ebs_iops" {
  description = "Daskhub EBS IOPS"
  default     = 3000
}

variable "daskhub_nodegroup_encrypted" {
  description = "Daskhub EBS Encrypted"
  default     = true
}

variable "daskhub_nodegroup_throughput" {
  description = "Daskhub EBS Throughput"
  default     = 125
}

variable "daskhub_nodegroup_volume_type" {
  description = "Daskhub EBS VolumeType"
  default     = "gp3"
}

variable "daskhub_nodegroup_http_tokens" {
  description = "Daskhub Metadata HTTP Tokens"
  default     = "optional"
}

variable "daskhub_nodegroup_http_put_response_hop_limit" {
  description = "Daskhub Metadata HTTP Put Response Hop Limit"
  default     = 2
}

variable "daskhub_nodegroup_name" {
  description = "Daskhub Nodegroup Name"
  default     = "dask-workers"
}

variable "daskhub_nodegroup_ami_type" {
  description = "Daskhub Nodegroup AMI Type"
  default     = "AL2_x86_64"
}

variable "daskhub_nodegroup_instance_types" {
  description = "Daskhub Nodegroup Instance Types"
  default     = ["m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge"]
}

variable "daskhub_nodegroup_capacity_type" {
  description = "Daskhub Nodegroup Capacity Type"
  default     = "SPOT"
}

variable "daskhub_nodegroup_min_size" {
  description = "Daskhub Nodegroup Min Cluster Size"
  default     = 1
}

variable "daskhub_nodegroup_max_size" {
  description = "Daskhub Nodegroup Max Cluster Size"
  default     = 30
}

variable "daskhub_nodegroup_desired_size" {
  description = "Daskhub Nodegroup Desired Cluster Size"
  default     = 1
}

variable "daskhub_helm_chart_version" {
  description = "Daskhub Helm Chart Version"
  default = "2022.10.0"
}

variable "daskhub_helm_chart_namespace" {
  description = "Daskhub Helm Chart Namespace"
  default     = "default"
}

variable "filmdrop_ebs_csi_driver_helm_name" {
  description = "FilmDrop EBS CSI Helm Name"
  default     = "filmdrop-aws-ebs-csi-driver"
}

variable "ebs_csi_driver_helm_chart_namespace" {
  description = "EBS CSI Helm Chart Namespace"
  default     = "kube-system"
}

variable "ebs_csi_driver_helm_chart_version" {
  description = "EBS CSI Helm Chart Version"
  default = "v1.13.0"
}

variable "zone_id" {
  description = "The DNS zone id to add the record to."
}

variable "domain_alias" {
  description = "Alternate alias for Jupyter Load Balancer"
}
