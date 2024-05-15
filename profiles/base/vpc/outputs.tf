output "vpc_cidr" {
  description = "FilmDrop VPC CIDR Range"
  value       = var.deploy_vpc_search ? module.vpc_search[0].vpc_cidr : var.deploy_vpc ? module.vpc_infra[0].vpc_cidr : var.vpc_cidr
}

output "private_subnet_ids" {
  description = "List of FilmDrop Private Subnet IDs"
  value       = var.deploy_vpc_search ? module.vpc_search[0].private_subnet_ids : var.deploy_vpc ? module.vpc_infra[0].private_subnet_ids : values(var.private_subnets_az_to_id_map)
}

output "public_subnet_ids" {
  description = "List of FilmDrop Public Subnet IDs"
  value       = var.deploy_vpc_search ? module.vpc_search[0].public_subnet_ids : var.deploy_vpc ? module.vpc_infra[0].public_subnet_ids : values(var.public_subnets_az_to_id_map)
}

output "private_avaliability_zones" {
  description = "List of FilmDrop Private Subnet Availability Zones"
  value       = var.deploy_vpc_search ? module.vpc_search[0].private_avaliability_zones : var.deploy_vpc ? module.vpc_infra[0].private_avaliability_zones : keys(var.private_subnets_az_to_id_map)
}

output "public_avaliability_zones" {
  description = "List of FilmDrop Public Subnet Availability Zones"
  value       = var.deploy_vpc_search ? module.vpc_search[0].public_avaliability_zones : var.deploy_vpc ? module.vpc_infra[0].public_avaliability_zones : keys(var.public_subnets_az_to_id_map)
}

output "vpc_id" {
  description = "FilmDrop VPC ID"
  value       = var.deploy_vpc_search ? module.vpc_search[0].vpc_id : var.deploy_vpc ? module.vpc_infra[0].vpc_id : var.vpc_id
}

output "security_group_id" {
  description = "ID of FilmDrop Default Security Group"
  value       = var.deploy_vpc_search ? module.vpc_search[0].security_group_id : var.deploy_vpc ? module.vpc_infra[0].security_group_id : var.security_group_id
}
