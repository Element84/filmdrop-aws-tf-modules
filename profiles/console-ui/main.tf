module "console-ui" {
  source = "../../modules/console-ui"

  vpc_id                 = var.vpc_id
  vpc_private_subnet_ids = var.private_subnet_ids
  vpc_security_group_ids = [var.security_group_id]

  filmdrop_ui_release_tag = var.console_ui_inputs.version
  console_ui_bucket_name  = var.console_ui_inputs.deploy_s3_bucket == false ? var.console_ui_inputs.external_content_bucket.external_content_website_bucket_name : var.console_ui_inputs.deploy_cloudfront ? module.cloudfront_s3_website[0].content_bucket_name : module.content_website[0].content_bucket

  filmdrop_ui_config    = filebase64(var.console_ui_inputs.filmdrop_ui_config_file)
  filmdrop_ui_logo_file = var.console_ui_inputs.filmdrop_ui_logo_file
  filmdrop_ui_logo      = filebase64(var.console_ui_inputs.filmdrop_ui_logo_file)
}

module "cloudfront_s3_website" {
  source = "../../modules/cloudfront/s3_website"
  count  = var.console_ui_inputs.deploy_cloudfront ? 1 : 0
  providers = {
    aws.east = aws.east
    aws.main = aws.main
  }

  zone_id                      = var.domain_zone
  domain_alias                 = var.console_ui_inputs.domain_alias
  domain_name                  = var.console_ui_inputs.deploy_s3_bucket == false ? var.console_ui_inputs.external_content_bucket.external_content_bucket_regional_domain_name : ""
  application_name             = var.console_ui_inputs.app_name
  custom_error_response        = var.console_ui_inputs.custom_error_response
  project_name                 = var.project_name
  environment                  = var.environment
  create_log_bucket            = var.create_log_bucket
  log_bucket_name              = var.log_bucket_name
  log_bucket_domain_name       = var.log_bucket_domain_name
  filmdrop_archive_bucket_name = var.s3_logs_archive_bucket
  cf_function_name             = var.console_ui_inputs.auth_function.cf_function_name
  cf_function_runtime          = var.console_ui_inputs.auth_function.cf_function_runtime
  cf_function_code_path        = var.console_ui_inputs.auth_function.cf_function_code_path
  attach_cf_function           = var.console_ui_inputs.auth_function.attach_cf_function
  cf_function_event_type       = var.console_ui_inputs.auth_function.cf_function_event_type
  create_cf_function           = var.console_ui_inputs.auth_function.create_cf_function
  create_cf_basicauth_function = var.console_ui_inputs.auth_function.create_cf_basicauth_function
  cf_function_arn              = var.console_ui_inputs.auth_function.cf_function_arn
  web_acl_id                   = var.console_ui_inputs.web_acl_id == "" ? var.fd_web_acl_id : var.console_ui_inputs.web_acl_id
}

module "content_website" {
  count  = var.console_ui_inputs.deploy_s3_bucket == true && var.console_ui_inputs.deploy_cloudfront == false ? 1 : 0
  source = "../../modules/cloudfront/content"

  origin_id = local.origin_id_prefix
}

locals {
  origin_id_prefix = lower(substr(replace("fd-${var.project_name}-${var.environment}-${var.console_ui_inputs.app_name}", "_", "-"), 0, 63))
}
