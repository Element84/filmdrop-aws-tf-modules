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

resource "aws_s3_bucket_lifecycle_configuration" "cirrus_payload_bucket" {
  count = var.cirrus_payload_bucket == "" && var.payload_tmp_lifecycle_expiration_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.cirrus_payload_bucket[0].id

  rule {
    id     = "expire-tmp-objects"
    status = "Enabled"

    filter {
      prefix = "${var.payload_root_prefix}/tmp/"
    }

    expiration {
      days = var.payload_tmp_lifecycle_expiration_days
    }
  }
}
