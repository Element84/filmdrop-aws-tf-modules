data "aws_caller_identity" "current" {
}

data "aws_canonical_user_id" "current" {
}

locals {
  origin_id              = random_id.suffix.hex
  log_bucket             = "cloudfront-filmdrop-logs-${local.origin_id}"
  log_bucket_domain_name = "${local.log_bucket}.s3.amazonaws.com"
}
