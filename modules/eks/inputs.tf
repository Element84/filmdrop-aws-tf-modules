variable cluster_name {
  type        = string
  description = "The name of the EKS cluster."
  default     = "eks"
}

variable cluster_version {
  type        = string
  description = "The version of the EKS cluster."
  default     = "1.25"
}

variable node_group_instance_type {
  type        = list(string)
  description = "The instance type of the worker group nodes. Must be large enough to support the amount of NICS assigned to pods."
  default     = ["t3.large"]
}

variable vpc_id {
  type        = string
  description = "ID of the VPC that already exists where the EKS cluster should be created."
}

variable subnet_ids {
  type        = list(string)
  description = "Subnets within the VPC where the EKS cluster should be created."
}

variable autoscaling_group_desired_capacity {
  type        = number
  description = "The desired number of nodes the worker group should attempt to maintain."
  default     = 1
}

variable autoscaling_group_min_size {
  type        = number
  description = "The minimum number of nodes the worker group can scale to."
  default     = 1
}

variable autoscaling_group_max_size {
  type        = number
  description = "The maximum number of nodes the worker group can scale to."
  default     = 1
}

variable nodegroup_name {
  type        = string
  description = "EKS Node Group name."
  default     = "workers"
}
