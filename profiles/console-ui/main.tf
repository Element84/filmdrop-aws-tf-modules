module "console-ui" {
  source = "../../modules/console-ui"

  vpc_id                 = var.vpc_id
  vpc_private_subnet_ids = var.private_subnet_ids
  vpc_security_group_ids = [var.security_group_id]

  filmdrop_ui_release    = var.console_ui_inputs.filmdrop_ui_release
  console_ui_bucket_name = module.cloudfront_s3_website.content_bucket_name

  filmdrop_ui_config    = filebase64(var.console_ui_inputs.filmdrop_ui_config_file)
  filmdrop_ui_logo_file = var.console_ui_inputs.filmdrop_ui_logo_file
  filmdrop_ui_logo      = filebase64(var.console_ui_inputs.filmdrop_ui_logo_file)
}

module "cloudfront_s3_website" {
  source = "../../modules/cloudfront/s3_website"

  providers = {
    aws.east = aws.east
    aws.main = aws.main
  }

  zone_id                      = var.domain_zone
  domain_alias                 = var.console_ui_inputs.domain_alias
  application_name             = var.console_ui_inputs.app_name
  custom_error_response        = var.console_ui_inputs.custom_error_response
  project_name                 = var.project_name
  environment                  = var.environment
  create_log_bucket            = var.create_log_bucket
  log_bucket_name              = var.log_bucket_name
  log_bucket_domain_name       = var.log_bucket_domain_name
  filmdrop_archive_bucket_name = var.s3_logs_archive_bucket
}
