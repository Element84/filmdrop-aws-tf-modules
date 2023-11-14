resource "aws_s3_bucket" "s3_access_logs_bucket" {
  bucket_prefix = var.log_bucket_name
}

resource "aws_s3_bucket_acl" "s3_access_logs_bucket_acl" {
  bucket = aws_s3_bucket.s3_access_logs_bucket.id
  acl    = var.log_bucket_acl
}
