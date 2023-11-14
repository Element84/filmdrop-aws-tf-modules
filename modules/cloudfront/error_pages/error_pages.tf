
resource "aws_s3_bucket" "error_bucket" {
  bucket = lower("${local.error_pages_id}")
}

resource "aws_s3_object" "base_custom_error_pages_directory" {
  bucket       = aws_s3_bucket.error_bucket.id
  acl          = "private"
  key          = "${local.error_pages_id}/"
  content_type = "application/x-directory"
}

resource "aws_s3_bucket_ownership_controls" "error_bucket_ownership_controls" {
  bucket = aws_s3_bucket.error_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "error_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.error_bucket_ownership_controls]
  bucket = aws_s3_bucket.error_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "error_bucket_versioning" {
  bucket = aws_s3_bucket.error_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
