#S3 buckets for waf
resource "aws_s3_bucket" "waf_buckets" {
    for_each = var.waf_buckets_map
    bucket = each.value

    tags = merge({ "Name" = "${each.value}" }, var.base_tags )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_buckets_encryption" {
  for_each = aws_s3_bucket.waf_buckets

  bucket = each.value.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "waf_buckets_public_access_block" {
  for_each = aws_s3_bucket.waf_buckets

  bucket = each.value.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#Vpc logs bucket with default name
resource "aws_s3_bucket" "vpc_log_bucket" {
      tags = merge({ "Name" = "filmdrop-vpc-log-bucket" }, var.base_tags )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_bucket_encryption" {
  bucket = aws_s3_bucket.vpc_log_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}