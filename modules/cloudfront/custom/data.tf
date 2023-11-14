data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "archive_file" "cloudfront_headers_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/headers"
  output_path = "${path.module}/cloudfront_headers_lambda_zip.zip"
}

resource "random_id" "suffix" {
  byte_length = 16
}
