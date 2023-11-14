variable "vpc_id" {
  description = "vpc id for codebuild to use"
}

variable "private_subnet_ids" {
  description = "list of subnet ids for codebuild to use"
  type        = list
}

variable "security_group_ids" {
  description = "list of security group ids for codebuild to use"
  type        = list
}

variable "titiler_stage" {
  description = "Titiler stage"
  default     = "dev"
}

variable "prefix" {
  description = "Titiler prefix"
  default     = ""
}
