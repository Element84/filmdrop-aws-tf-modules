output "vpc_cidr" {
  description = "FilmDrop VPC CIDR Range"
  value       = module.filmdrop_vpc.vpc_cidr
}

output "private_subnet_ids" {
  description = "List of FilmDrop Private Subnet IDs"
  value       = module.filmdrop_vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of FilmDrop Public Subnet IDs"
  value       = module.filmdrop_vpc.public_subnet_ids
}

output "private_avaliability_zones" {
  description = "List of FilmDrop Private Subnet Availability Zones"
  value       = module.filmdrop_vpc.private_avaliability_zones
}

output "public_avaliability_zones" {
  description = "List of FilmDrop Public Subnet Availability Zones"
  value       = module.filmdrop_vpc.public_avaliability_zones
}

output "vpc_id" {
  description = "FilmDrop VPC ID"
  value       = module.filmdrop_vpc.vpc_id
}

output "security_group_id" {
  description = "ID of FilmDrop Default Security Group"
  value       = module.filmdrop_vpc.security_group_id
}

output "s3_access_log_bucket" {
  description = "FilmDrop S3 Access Log Bucket Name"
  value       = var.deploy_log_archive ? module.filmdrop_log_archive[0].s3_access_log_bucket : var.s3_access_log_bucket
}

output "s3_logs_archive_bucket" {
  description = "FilmDrop S3 Archive Log Bucket Name"
  value       = var.deploy_log_archive ? module.filmdrop_log_archive[0].s3_logs_archive_bucket : var.s3_logs_archive_bucket
}
