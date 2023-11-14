###############
# Sample data S3 Bucket and s3 access logs for it.
# This is usually not needed, but if it is needed for any client to put the
# STAC Items temporarily
###############

resource "aws_s3_bucket" "project_filmdrop_sample_data_bucket" {
  bucket        = var.project_sample_data_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_acl" "project_filmdrop_sample_data_bucket_acl" {
  bucket = aws_s3_bucket.project_filmdrop_sample_data_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_logging" "project_filmdrop_sample_data_bucket_logging" {
  bucket        = aws_s3_bucket.project_filmdrop_sample_data_bucket.id
  target_bucket = var.s3_access_log_bucket
  target_prefix = "log/"
}

resource "null_resource" "cleanup_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.project_filmdrop_sample_data_bucket.id
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
    aws_s3_bucket.project_filmdrop_sample_data_bucket
  ]
}
