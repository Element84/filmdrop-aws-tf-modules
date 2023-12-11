output "vpc_id" {
  value = module.filmdrop.vpc_id
}

output "vpc_cidr" {
  value = module.filmdrop.vpc_cidr
}

output "private_subnet_ids" {
  value = module.filmdrop.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.filmdrop.public_subnet_ids
}

output "security_group_id" {
  value = module.filmdrop.security_group_id
}

output "private_avaliability_zones" {
  value = module.filmdrop.private_avaliability_zones
}

output "public_avaliability_zones" {
  value = module.filmdrop.public_avaliability_zones
}

output "s3_logs_archive_bucket" {
  value = module.filmdrop.s3_logs_archive_bucket
}

output "s3_access_log_bucket" {
  value = module.filmdrop.s3_access_log_bucket
}

output "analytics_url" {
  value = module.filmdrop.analytics_url
}

output "stac_url" {
  value = module.filmdrop.stac_url
}

output "stac_opensearch_domain_name" {
  value = module.filmdrop.stac_opensearch_domain_name
}

output "stac_opensearch_endpoint" {
  value = module.filmdrop.stac_opensearch_endpoint
}

output "console_ui_url" {
  value = module.filmdrop.console_ui_url
}

output "cirrus_dashboard_url" {
  value = module.filmdrop.cirrus_dashboard_url
}

output "titiler_url" {
  value = module.filmdrop.titiler_url
}

output "stac_ingest_queue_arn" {
  value = module.filmdrop.stac_ingest_queue_arn
}

output "stac_ingest_queue_url" {
  value = module.filmdrop.stac_ingest_queue_url
}
