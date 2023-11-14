variable "vpc_id" {
  description = "ID of the VPC that already exists where the SSM Bastion should be created."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID within the VPC where the SSM Bastion should be created."
  type        = string
}

variable "ami_name_filter" {
  description = "The search filter string for the AMI."
  type        = string
  default     = "amzn2-ami-hvm-*-x86_64-ebs"
}

variable "key_name" {
  description = "Optional ssh keypair name."
  type        = string
  default     = ""
}

variable "swap_volume_size" {
  description = "Size of swap EBS volume."
  type        = string
  default     = "2"
}

variable "instance_type" {
  description = "EC2 Instance type."
  type        = string
  default     = "t2.micro"
}

variable "attach_accelerator_policy" {
  description = "Attach LZA policy to EKS worker nodes."
  type        = bool
  default     = false
}

variable "vpc_cidr_range" {
  description = "CIDR Range for FilmDrop vpc"
  type        = string
}
