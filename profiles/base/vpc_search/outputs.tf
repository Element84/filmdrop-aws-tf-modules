output "vpc_cidr" {
  description = "FilmDrop VPC CIDR Range"
  value       = data.aws_vpc.vpc.cidr_block
}

output "private_subnet_ids" {
  description = "List of FilmDrop Private Subnet IDs"
  value       = values(data.aws_subnet.private_subnets)[*].id
}

output "public_subnet_ids" {
  description = "List of FilmDrop Public Subnet IDs"
  value       = values(data.aws_subnet.public_subnets)[*].id
}

output "private_avaliability_zones" {
  description = "List of FilmDrop Private Subnet Availability Zones"
  value       = values(data.aws_subnet.private_subnets)[*].availability_zone
}

output "public_avaliability_zones" {
  description = "List of FilmDrop Public Subnet Availability Zones"
  value       = values(data.aws_subnet.public_subnets)[*].availability_zone
}

output "vpc_id" {
  description = "FilmDrop VPC ID"
  value       = data.aws_vpc.vpc.id
}

output "security_group_id" {
  description = "ID of FilmDrop Default Security Group"
  value       = data.aws_security_group.security_group.id
}
