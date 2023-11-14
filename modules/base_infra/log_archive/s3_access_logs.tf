resource "aws_s3_bucket" "s3_access_logs_bucket" {
  bucket_prefix = var.access_log_bucket_prefix == "" ? lower(substr(replace("fd-${var.project_name}-${var.environment}-access-logs-", "_", "-"), 0, 63)) : var.access_log_bucket_prefix
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "s3_access_logs_bucket_ownership_controls" {
  bucket = aws_s3_bucket.s3_access_logs_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "s3_access_logs_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_access_logs_bucket_ownership_controls]
  bucket     = aws_s3_bucket.s3_access_logs_bucket.id
  acl        = var.log_bucket_acl
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

resource "null_resource" "cleanup_s3_access_logs_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.s3_access_logs_bucket.id
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
    aws_s3_bucket.s3_access_logs_bucket
  ]
}
