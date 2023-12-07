output "vpc_id" {
  value = module.base_infra.vpc_id
}

output "vpc_cidr" {
  value = module.base_infra.vpc_cidr
}

output "private_subnet_ids" {
  value = module.base_infra.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.base_infra.public_subnet_ids
}

output "security_group_id" {
  value = module.base_infra.security_group_id
}

output "private_avaliability_zones" {
  value = module.base_infra.private_avaliability_zones
}

output "public_avaliability_zones" {
  value = module.base_infra.public_avaliability_zones
}

output "s3_logs_archive_bucket" {
  value = module.base_infra.s3_logs_archive_bucket
}

output "s3_access_log_bucket" {
  value = module.base_infra.s3_access_log_bucket
}

output "analytics_url" {
  value = var.deploy_analytics ? module.analytics[0].analytics_url : ""
}

output "stac_url" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_url : ""
}

output "stac_opensearch_domain_name" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_opensearch_domain_name : ""
}

output "stac_opensearch_endpoint" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_opensearch_endpoint : ""
}

output "console_ui_url" {
  value = var.deploy_console_ui ? module.console-ui[0].console_ui_url : ""
}

output "cirrus_dashboard_url" {
  value = var.deploy_cirrus_dashboard ? module.cirrus-dashboard[0].cirrus_dashboard_url : ""
}

output "titiler_url" {
  value = var.deploy_titiler ? module.titiler[0].titiler_url : ""
}

output "stac_ingest_queue_arn" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_ingest_queue_arn : ""
}
