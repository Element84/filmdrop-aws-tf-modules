module "cloudfront_logging" {
  source = "../logging"

  providers = {
    aws = aws.east
  }

  create_log_bucket             = var.create_log_bucket
  log_bucket_name               = var.log_bucket_name
  log_bucket_domain_name        = var.log_bucket_domain_name
  filmdrop_archive_bucket_name  = var.filmdrop_archive_bucket_name
}

module "cloudfront_custom_error_pages" {
  source = "../error_pages"

  providers = {
    aws = aws.east
  }

  logging_origin_id                       = module.cloudfront_logging.origin_id
  cloudfront_origin_access_identity_arn   = module.cloudfront_logging.cloudfront_origin_access_identity_arn
}