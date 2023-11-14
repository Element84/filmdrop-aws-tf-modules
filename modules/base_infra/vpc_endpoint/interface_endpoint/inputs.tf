variable "service_name" {
  description = "The AWS service name for the VPC Endpoint"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used."
  type        = string
}

variable "private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC."
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "The ID of one or more subnets in which to create a network interface for the endpoint."
  type        = list(string)
}

variable "security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface."
  type        = list(string)
}
