variable "service_name" {
  description = "The AWS service name for the VPC Endpoint"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used."
  type        = string
}

variable "route_table_ids" {
  description = "The ID of one or more route tables to associate with the network interface."
  type        = list(string)
}
