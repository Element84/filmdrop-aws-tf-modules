module "cloudfront_logging" {
  source = "../logging"

  providers = {
    aws = aws.east
  }
}

module "cloudfront_custom_error_pages" {
  source = "../error_pages"

  providers = {
    aws = aws.east
  }

  logging_origin_id                       = module.cloudfront_logging.origin_id
  cloudfront_origin_access_identity_arn   = module.cloudfront_logging.cloudfront_origin_access_identity_arn
}