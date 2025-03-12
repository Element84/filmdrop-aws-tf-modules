resource "aws_s3_bucket" "cirrus_data_bucket" {
  count = var.cirrus_data_bucket == "" ? 1 : 0

  bucket_prefix = var.cirrus_data_bucket == "" ? "${var.resource_prefix}-data-" : var.cirrus_data_bucket
  force_destroy = true
}

resource "aws_s3_bucket" "cirrus_payload_bucket" {
  count = var.cirrus_payload_bucket == "" ? 1 : 0

  bucket_prefix = var.cirrus_payload_bucket == "" ? "${var.resource_prefix}-payload-" : var.cirrus_payload_bucket
  force_destroy = true
}
