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
          "arn:aws:s3:::${local.log_bucket}/cloudfront*"
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
