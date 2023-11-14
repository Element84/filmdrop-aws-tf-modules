resource "aws_s3_bucket" "s3_access_logs_bucket" {
  bucket_prefix = var.access_log_bucket_prefix == "" ? "filmdrop-${var.environment}-access-logs-" : var.access_log_bucket_prefix
}

resource "aws_s3_bucket_acl" "s3_access_logs_bucket_acl" {
  bucket = aws_s3_bucket.s3_access_logs_bucket.id
  acl    = var.log_bucket_acl
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_access_logs_bucket_encryption" {
  bucket = aws_s3_bucket.s3_access_logs_bucket.id

  rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_logs_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.s3_access_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
