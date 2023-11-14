
resource "aws_s3_bucket" "content_bucket" {
  bucket_prefix = lower(substr(replace("${var.origin_id}-content-", "_", "-"), 0, 60))
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "content_bucket_ownership_controls" {
  bucket = aws_s3_bucket.content_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "content_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.content_bucket_ownership_controls]
  bucket     = aws_s3_bucket.content_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_versioning" "content_bucket_versioning" {
  bucket = aws_s3_bucket.content_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "null_resource" "cleanup_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.content_bucket.id
    region      = data.aws_region.current.name
    account     = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "FilmDrop CloudFront bucket has been created."

aws s3 ls s3://${self.triggers.bucket_name}
EOF

  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "Cleaning FilmDrop bucket."

aws s3 rm s3://${self.triggers.bucket_name}/ --recursive
EOF
  }


  depends_on = [
    aws_s3_bucket.content_bucket
  ]
}
