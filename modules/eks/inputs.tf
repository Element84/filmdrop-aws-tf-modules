variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster."
  default     = "eks"
}

variable "cluster_version" {
  type        = string
  description = "The version of the EKS cluster."
  default     = "1.29"
}

variable "eks_managed_node_group" {
  description = "Inputs for EKS cluster managed node group"
  type = object({
    node_group_name                    = string
    ami_type                           = string
    node_group_capacity_type           = string
    node_group_disk_size_gb            = number
    instance_types                     = list(string)
    subnet_ids                         = list(string)
    autoscaling_group_desired_capacity = number
    autoscaling_group_min_size         = number
    autoscaling_group_max_size         = number
  })
  default = {
    node_group_name                    = "fd-managed-group-nodes"
    ami_type                           = "AL2_x86_64"
    node_group_capacity_type           = "ON_DEMAND"
    node_group_disk_size_gb            = 50
    instance_types                     = ["t3.large"]
    subnet_ids                         = ["managed-group-subnet-ids"]
    autoscaling_group_desired_capacity = 1
    autoscaling_group_min_size         = 1
    autoscaling_group_max_size         = 1

  }
}

variable "eks_self_managed_node_group" {
  description = "Inputs for EKS cluster self-managed node group"
  type = object({
    node_group_name                    = string
    node_group_capacity_type           = string
    node_group_volume_type             = string
    node_group_disk_size_gb            = number
    instance_type                      = string
    subnet_ids                         = list(string)
    autoscaling_group_desired_capacity = number
    autoscaling_group_min_size         = number
    autoscaling_group_max_size         = number
  })
  default = {
    node_group_name                    = "fd-self-managed-group-nodes"
    node_group_capacity_type           = "ON_DEMAND"
    node_group_volume_type             = "gp3"
    node_group_disk_size_gb            = 50
    instance_type                      = "t3.large"
    subnet_ids                         = ["self-managed-group-subnet-ids"]
    autoscaling_group_desired_capacity = 0
    autoscaling_group_min_size         = 0
    autoscaling_group_max_size         = 0
  }
}

variable "control_plane_subnet_ids" {
  type        = list(string)
  description = "Subnets within the VPC where the EKS cluster control plane should be created."
}

variable "node_group_subnet_ids" {
  type        = list(string)
  description = "Subnets within the VPC where the EKS node groups should be created."
}

variable "endpoint_private_access" {
  type        = bool
  description = "Whether the Amazon EKS private API server endpoint is enabled."
  default     = true
}

variable "endpoint_public_access" {
  type        = bool
  description = "Whether the Amazon EKS public API server endpoint is enabled."
  default     = false
}

