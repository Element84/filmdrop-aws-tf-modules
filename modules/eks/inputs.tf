variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster."
  default     = "eks"
}

variable "cluster_version" {
  type        = string
  description = "The version of the EKS cluster."
  default     = "1.25"
}

variable "node_group_instance_type" {
  type        = list(string)
  description = "The instance type of the worker group nodes. Must be large enough to support the amount of NICS assigned to pods."
  default     = ["t3.large"]
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets within the VPC where the EKS cluster should be created."
}

variable "autoscaling_group_desired_capacity" {
  type        = number
  description = "The desired number of nodes the worker group should attempt to maintain."
  default     = 1
}

variable "autoscaling_group_min_size" {
  type        = number
  description = "The minimum number of nodes the worker group can scale to."
  default     = 1
}

variable "autoscaling_group_max_size" {
  type        = number
  description = "The maximum number of nodes the worker group can scale to."
  default     = 1
}

variable "nodegroup_name" {
  type        = string
  description = "EKS Node Group name."
  default     = "workers"
}

variable "attach_accelerator_policy" {
  type        = bool
  description = "Attach LZA policy to EKS worker nodes."
  default     = false
}

variable "node_group_capacity_type" {
  type        = string
  description = "Type of capacity associated with the EKS Node Group. Valid values are ON_DEMAND or SPOT."
  default     = "ON_DEMAND"
}

variable "node_group_disk_size" {
  type        = number
  description = "Disk size in GiB for worker nodes."
  default     = 50
}
