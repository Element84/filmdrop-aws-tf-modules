variable "vpc_id" {
  description = "vpc id for codebuild to use"
  type        = string
}

variable "private_subnet_ids" {
  description = "list of subnet ids for codebuild to use"
  type        = list(any)
}

variable "security_group_ids" {
  description = "list of security group ids for codebuild to use"
  type        = list(any)
}

variable "environment" {
  description = "Titiler stage"
  type        = string
}

variable "prefix" {
  description = "Titiler prefix"
  type        = string
}
