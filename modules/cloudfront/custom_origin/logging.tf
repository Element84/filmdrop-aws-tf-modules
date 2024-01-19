resource "aws_s3_bucket" "log_bucket" {
  count         = var.create_log_bucket ? 1 : 0
  bucket_prefix = "${lower(substr(replace(local.origin_id_prefix, "_", "-"), 0, 55))}-log-"
  force_destroy = true
}

resource "aws_s3_bucket_replication_configuration" "log_bucket_replication" {
  count      = var.create_log_bucket ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.log_bucket_versioning]

  role   = aws_iam_role.cloudfront_bucket_replicator_role.arn
  bucket = aws_s3_bucket_versioning.log_bucket_versioning[0].id

  rule {
    id       = "filmdrop-archive-bucket-replication"
    status   = "Enabled"
    priority = 1
    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket  = "arn:aws:s3:::${var.filmdrop_archive_bucket_name}"
      account = data.aws_caller_identity.current.id

      access_control_translation {
        owner = "Destination"
      }
    }
  }
}


resource "aws_s3_bucket_ownership_controls" "log_bucket_ownership_controls" {
  count  = var.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  count      = var.create_log_bucket ? 1 : 0
  bucket     = aws_s3_bucket.log_bucket[0].id
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_ownership_controls]

  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    grant {
      grantee {
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "READ_ACP"
    }

    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "WRITE"
    }

    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  count  = var.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  count  = var.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
              "AWS": "${data.aws_caller_identity.current.account_id}"
            },
            "Action": [
              "s3:GetBucketACL",
              "s3:PutBucketACL"
            ],
            "Resource": "arn:aws:s3:::${var.create_log_bucket ? aws_s3_bucket.log_bucket[0].id : var.log_bucket_name}"
        }
    ]
}
EOF

}


resource "null_resource" "cleanup_bucket" {
  count = var.create_log_bucket ? 1 : 0

  triggers = {
    bucket_name = aws_s3_bucket.log_bucket[0].id
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
    aws_s3_bucket.log_bucket
  ]
}
