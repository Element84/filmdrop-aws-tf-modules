resource "aws_iam_role" "cloudfront_bucket_replicator_role" {
  name_prefix = "FilmDropCloudFrontBucketReplicatorRole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
POLICY

}

resource "aws_iam_policy" "cloudfront_bucket_replicator_policy" {
  name_prefix = "FilmDropCloudFrontBucketReplicatorPolicy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionForReplication"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ],
      "Effect": "Allow",
      "Resource": [
          "arn:aws:s3:::${var.filmdrop_archive_bucket_name}/cloudfront*",
          "arn:aws:s3:::${var.create_log_bucket ? aws_s3_bucket.log_bucket[0].id : var.log_bucket_name}/cloudfront*"
      ]
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "cloudfront_bucket_replicator" {
  role       = aws_iam_role.cloudfront_bucket_replicator_role.name
  policy_arn = aws_iam_policy.cloudfront_bucket_replicator_policy.arn
}

resource "aws_s3_bucket_policy" "cloudfront_custom_content_policy" {
  provider = aws.main
  count    = var.create_content_website ? 1 : 0
  bucket   = module.content_website[0].content_bucket

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS":  [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "${aws_cloudfront_origin_access_identity.filmdrop_origin_access_identity.iam_arn}"
          ]
        },
        "Action": "s3:GetObject*",
        "Resource": "${module.content_website[0].content_bucket_arn}/*"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "AWS":  [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "${aws_cloudfront_origin_access_identity.filmdrop_origin_access_identity.iam_arn}"
          ]
        },
        "Action": "s3:ListBucket",
        "Resource": "${module.content_website[0].content_bucket_arn}"
      },
      {
        "Effect": "Allow",
        "Condition": {
          "StringEquals": {
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        },
        "Principal": {
          "AWS":  [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "${aws_cloudfront_origin_access_identity.filmdrop_origin_access_identity.iam_arn}"
          ]
        },
        "Action": "s3:PutObject*",
        "Resource": "${module.content_website[0].content_bucket_arn}/*"
      }
  ]
}
EOF

}
