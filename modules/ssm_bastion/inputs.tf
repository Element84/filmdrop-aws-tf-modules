variable vpc_id {
  type        = string
  description = "ID of the VPC that already exists where the SSM Bastion should be created."
}

variable subnet_id {
  type        = string
  description = "Subnet ID within the VPC where the SSM Bastion should be created."
}

variable ami_name_filter {
  type        =  string
  description = "The search filter string for the AMI."
  default     = "amzn2-ami-hvm-*-x86_64-ebs"
}

variable key_name {
  description = "Optional ssh keypair name."
  default     = ""
}

variable swap_volume_size {
  description = "Size of swap EBS volume."
  default     = "2"
}

variable "instance_type" {
  description = "EC2 Instance type."
  default     = "t2.micro"
}

variable attach_accelerator_policy {
  type        = bool
  description = "Attach LZA policy to EKS worker nodes."
  default     = false
}

variable "vpc_cidr_range" {
  description = "CIDR Range for FilmDrop vpc"
}
