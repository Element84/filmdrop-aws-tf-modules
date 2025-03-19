resource "aws_s3_bucket" "cirrus_data_bucket" {
  count = var.cirrus_data_bucket == "" ? 1 : 0

  bucket_prefix = "${var.resource_prefix}-data-"
  force_destroy = true
}

resource "aws_s3_bucket" "cirrus_payload_bucket" {
  count = var.cirrus_payload_bucket == "" ? 1 : 0

  bucket_prefix = "${var.resource_prefix}-payload-"
  force_destroy = true
}
