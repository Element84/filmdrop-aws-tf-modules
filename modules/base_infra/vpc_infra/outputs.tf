output "nat_gateway_ids" {
  description = "List of FilmDrop NAT Gateway IDs"
  value       = values(aws_nat_gateway.ngws)[*].id

}

output "eip_ids" {
  description = "List of EIP IDs"
  value       = values(aws_eip.eips)[*].id
}

output "vpc_id" {
  description = "FilmDrop VPC ID"
  value       = aws_vpc.filmdrop_vpc.id
}

output "private_subnet_ids" {
  description = "List of FilmDrop Private Subnet IDs"
  value       = values(aws_subnet.private_subnets)[*].id
}

output "public_subnet_ids" {
  description = "List of FilmDrop Public Subnet IDs"
  value       = values(aws_subnet.public_subnets)[*].id
}

output "private_avaliability_zones" {
  description = "List of FilmDrop Private Subnet Availability Zones"
  value       = keys(var.private_subnets_az_to_id_map)
}

output "public_avaliability_zones" {
  description = "List of FilmDrop Public Subnet Availability Zones"
  value       = keys(var.public_subnets_az_to_id_map)
}

output "security_group_id" {
  description = "ID of FilmDrop Default Security Group"
  value       = aws_security_group.filmdrop_vpc_default_sg.id
}

output "vpc_cidr" {
  description = "FilmDrop VPC CIDR Range"
  value       = var.vpc_cidr
}
