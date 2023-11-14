data "aws_caller_identity" "current" {
}

data "aws_canonical_user_id" "current" {
}

data "aws_region" "current" {
}

data "archive_file" "cloudfront_headers_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/headers"
  output_path = "${path.module}/cloudfront_headers_lambda_zip.zip"
}

locals {
  origin_id_prefix = lower(substr(replace("fd-${var.project_name}-${var.environment}-${var.application_name}", "_", "-"), 0, 63))
}
