resource "aws_kms_key" "bucket_encryption_key" {
  enable_key_rotation = true

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.ssm_bastion_role.arn}"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_s3_bucket" "filmdrop_public_keys_bucket" {
  bucket_prefix = "filmdrop-public-keys-"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "filmdrop_public_keys_bucket_encryption" {
  bucket = aws_s3_bucket.filmdrop_public_keys_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_encryption_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}


data "aws_iam_policy_document" "filmdrop_public_keys_bucket_policy_document" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [aws_s3_bucket.filmdrop_public_keys_bucket.arn, "${aws_s3_bucket.filmdrop_public_keys_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "filmdrop_public_keys_bucket_policy" {
  bucket = aws_s3_bucket.filmdrop_public_keys_bucket.id
  policy = data.aws_iam_policy_document.filmdrop_public_keys_bucket_policy_document.json
}
