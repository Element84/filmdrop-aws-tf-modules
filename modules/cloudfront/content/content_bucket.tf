
resource "aws_s3_bucket" "content_bucket" {
  bucket = "${local.content_pages_id}"
}

resource "aws_s3_bucket_acl" "content_bucket_acl" {
  bucket = aws_s3_bucket.content_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "content_bucket_versioning" {
  bucket = aws_s3_bucket.content_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
