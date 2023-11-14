resource "aws_s3_bucket" "s3_logs_archive_bucket" {
  bucket_prefix = var.archive_log_bucket_prefix == "" ? lower(substr(replace("fd-${var.project_name}-${var.environment}-logs-archive-", "_", "-"), 0, 63)) : var.archive_log_bucket_prefix
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "s3_logs_archive_bucket_ownership_controls" {
  bucket = aws_s3_bucket.s3_logs_archive_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "s3_logs_archive_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_logs_archive_bucket_ownership_controls]
  bucket     = aws_s3_bucket.s3_logs_archive_bucket.id

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

resource "aws_s3_bucket_policy" "s3_logs_archive_bucket_policy" {
  bucket = aws_s3_bucket.s3_logs_archive_bucket.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CloudTrailACL",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.s3_logs_archive_bucket.arn}"
        },
        {
            "Sid": "CloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.s3_logs_archive_bucket.arn}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AWSLogDeliveryACL",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.s3_logs_archive_bucket.arn}"
        },
        {
            "Sid": "AWSLogDeliveryWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.s3_logs_archive_bucket.arn}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "CloudWatchLogsACL",
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.s3_logs_archive_bucket.arn}"
        },
        {
            "Sid": "CloudWatchLogsWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.s3_logs_archive_bucket.arn}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "ConfigACL",
            "Effect": "Allow",
            "Principal": {
                "Service": "config.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.s3_logs_archive_bucket.arn}"
        },
        {
            "Sid": "ConfigWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "config.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.s3_logs_archive_bucket.arn}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AllowCurrentUserACL",
            "Effect": "Allow",
            "Principal": {
              "AWS": "${data.aws_caller_identity.current.account_id}"
            },
            "Action": [
              "s3:GetBucketACL",
              "s3:PutBucketACL"
            ],
            "Resource": "arn:aws:s3:::${aws_s3_bucket.s3_logs_archive_bucket.id}"
        },
        {
            "Sid": "AllowCurrentUserReadOnly",
            "Effect": "Allow",
            "Principal": {
              "AWS": "${data.aws_caller_identity.current.account_id}"
            },
            "Action": [
                "s3:GetAccelerateConfiguration",
                "s3:GetAnalyticsConfiguration",
                "s3:GetBucketAcl",
                "s3:GetBucketCORS",
                "s3:GetBucketLocation",
                "s3:GetBucketLogging",
                "s3:GetBucketNotification",
                "s3:GetBucketPolicy",
                "s3:GetBucketRequestPayment",
                "s3:GetBucketTagging",
                "s3:GetBucketVersioning",
                "s3:GetBucketWebsite",
                "s3:GetEncryptionConfiguration",
                "s3:GetInventoryConfiguration",
                "s3:GetIpConfiguration",
                "s3:GetLifecycleConfiguration",
                "s3:GetMetricsConfiguration",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectTagging",
                "s3:GetObjectTorrent",
                "s3:GetObjectVersion",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectVersionForReplication",
                "s3:GetObjectVersionTagging",
                "s3:GetObjectVersionTorrent",
                "s3:GetReplicationConfiguration",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListBucketVersions",
                "s3:ListMultipartUploadParts",
                "s3:PutBucketNotification",
                "s3:ReplicateObject",
                "s3:ReplicateDelete",
                "s3:ReplicateTags",
                "s3:ObjectOwnerOverrideToBucketOwner"
            ],
            "Resource": [
              "arn:aws:s3:::${aws_s3_bucket.s3_logs_archive_bucket.id}",
              "arn:aws:s3:::${aws_s3_bucket.s3_logs_archive_bucket.id}/*"
            ]
        }
    ]
}
EOF

}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_logs_archive_bucket_encryption" {
  bucket = aws_s3_bucket.s3_logs_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_logs_archive_bucket_versioning" {
  bucket = aws_s3_bucket.s3_logs_archive_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_ssm_parameter" "s3_logs_archive_bucket_name_parameter" {
  type        = "String"
  name        = "filmdrop_${var.project_name}_${var.environment}_logs_bucket_name"
  description = "Name of the FilmDrop ${var.environment} Logs Bucket"
  value       = aws_s3_bucket.s3_logs_archive_bucket.id
}

resource "aws_s3_bucket_public_access_block" "s3_logs_archive_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.s3_logs_archive_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "null_resource" "cleanup_s3_logs_archive_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.s3_logs_archive_bucket.id
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
    aws_s3_bucket.s3_logs_archive_bucket
  ]
}
