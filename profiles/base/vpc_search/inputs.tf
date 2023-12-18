variable "vpc_tags" {
  description = "Tags for the vpc search."
  type        = map(any)
  default = {
    Name = "aws-controltower-VPC"
  }
}

variable "private_subnet_tags" {
  description = "Tags for the private subnet search."
  type        = map(any)
  default = {
    Name = "aws-controltower-PrivateSubnet*"
  }
}

variable "public_subnet_tags" {
  description = "Tags for the private subnet search."
  type        = map(any)
  default = {
    Name = "aws-controltower-PublicSubnet*"
  }
}

variable "security_group_name" {
  description = "Name for security group search."
  type        = string
  default     = "default"
}
