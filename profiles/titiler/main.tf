module "titiler" {
  source = "../../modules/mosaic-titiler"

  providers = {
    aws.east = aws.east
  }

  project_name                              = var.project_name
  environment                               = var.environment
  titiler_mosaicjson_release_tag            = var.titiler_inputs.version
  authorized_s3_arns                        = var.titiler_inputs.authorized_s3_arns
  waf_allowed_url                           = var.titiler_inputs.is_private_endpoint ? "" : var.titiler_inputs.mosaic_titiler_waf_allowed_url == "" ? var.stac_url : var.titiler_inputs.mosaic_titiler_waf_allowed_url
  request_host_header_override              = var.titiler_inputs.is_private_endpoint ? "" : var.titiler_inputs.mosaic_titiler_host_header
  mosaic_tile_timeout                       = var.titiler_inputs.mosaic_tile_timeout
  vpc_id                                    = var.vpc_id
  vpc_subnet_ids                            = var.private_subnet_ids
  vpc_security_group_ids                    = [var.security_group_id]
  private_api_additional_security_group_ids = var.titiler_inputs.private_api_additional_security_group_ids
  api_method_authorization_type             = var.titiler_inputs.api_method_authorization_type
  is_private_endpoint                       = var.titiler_inputs.is_private_endpoint
  domain_alias                              = var.titiler_inputs.domain_alias
  private_certificate_arn                   = var.titiler_inputs.private_certificate_arn
}

module "cloudfront_api_gateway_endpoint" {
  source = "../../modules/cloudfront/apigw_endpoint"
  count  = var.titiler_inputs.deploy_cloudfront ? 1 : 0

  providers = {
    aws.east = aws.east
  }

  zone_id                      = var.domain_zone
  domain_alias                 = var.titiler_inputs.domain_alias
  application_name             = var.titiler_inputs.app_name
  api_gateway_dns_name         = module.titiler.titiler_mosaic_api_gateway_endpoint
  api_gateway_path             = ""
  web_acl_id                   = module.titiler.titiler_mosaic_wafv2_web_acl_arn
  project_name                 = var.project_name
  environment                  = var.environment
  create_log_bucket            = var.create_log_bucket
  log_bucket_name              = var.log_bucket_name
  log_bucket_domain_name       = var.log_bucket_domain_name
  filmdrop_archive_bucket_name = var.s3_logs_archive_bucket
  cf_function_name             = var.titiler_inputs.auth_function.cf_function_name
  cf_function_runtime          = var.titiler_inputs.auth_function.cf_function_runtime
  cf_function_code_path        = var.titiler_inputs.auth_function.cf_function_code_path
  attach_cf_function           = var.titiler_inputs.auth_function.attach_cf_function
  cf_function_event_type       = var.titiler_inputs.auth_function.cf_function_event_type
  create_cf_function           = var.titiler_inputs.auth_function.create_cf_function
  create_cf_basicauth_function = var.titiler_inputs.auth_function.create_cf_basicauth_function
  cf_function_arn              = var.titiler_inputs.auth_function.cf_function_arn
}
