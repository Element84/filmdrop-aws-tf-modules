module "cirrus-dashboard" {
  source = "../../modules/cirrus-dashboard"

  vpc_id                        = var.vpc_id
  vpc_private_subnet_ids        = var.private_subnet_ids
  vpc_security_group_ids        = [var.security_group_id]
  cirrus_api_endpoint           = "${var.cirrus_dashboard_inputs.cirrus_api_endpoint_base}/${var.environment}/"
  metrics_api_endpoint          = "${var.cirrus_dashboard_inputs.cirrus_api_endpoint_base}/${var.environment}/stats/"
  cirrus_dashboard_bucket_name  = module.cloudfront_s3_website.content_bucket_name
  cirrus_dashboard_release      = var.cirrus_dashboard_inputs.cirrus_dashboard_release
}

module "cloudfront_s3_website" {
  source = "../../modules/cloudfront/s3_website"

  providers = {
    aws.east = aws.east
    aws.main = aws.main
  }

  zone_id                       = var.domain_zone
  domain_alias                  = var.cirrus_dashboard_inputs.domain_alias
  application_name              = var.cirrus_dashboard_inputs.app_name
  custom_error_response         = var.cirrus_dashboard_inputs.custom_error_response
  project_name                  = var.project_name
  environment                   = var.environment
  create_log_bucket             = var.create_log_bucket
  log_bucket_name               = var.log_bucket_name
  log_bucket_domain_name        = var.log_bucket_domain_name
  filmdrop_archive_bucket_name  = var.s3_logs_archive_bucket
}
