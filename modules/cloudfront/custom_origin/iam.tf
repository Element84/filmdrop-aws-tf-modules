#IAM roles and policies for Lambda that Sets CloudFront Custom Headers

data "aws_iam_policy_document" "cloudfront_headers_lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudfront_headers_lambda_role" {
  name_prefix        = "FilmDropCloudFront"
  assume_role_policy = data.aws_iam_policy_document.cloudfront_headers_lambda_assume_role.json
}

data "aws_iam_policy_document" "cloudfront_headers_lambda" {
  statement {
    sid    = "CloudFrontDistributionAccess"
    effect = "Allow"

    actions = [
      "cloudfront:GetDistributionConfig",
      "cloudfront:UpdateDistribution",
    ]

    resources = [aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.arn]
  }

  statement {
    sid    = "SSMParameterAccess"
    effect = "Allow"

    actions = [
      "ssm:PutParameter",
    ]

    resources = [aws_ssm_parameter.cloudfront_x_forwarded_host.arn]
  }

  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.origin_id_prefix}-headers:*"]
  }
}

resource "aws_iam_policy" "cloudfront_headers_lambda_policy" {
  name_prefix = "FilmDropCloudFront"
  policy      = data.aws_iam_policy_document.cloudfront_headers_lambda.json
}

resource "aws_iam_role_policy_attachment" "cloudfront_header_lambda" {
  role       = aws_iam_role.cloudfront_headers_lambda_role.name
  policy_arn = aws_iam_policy.cloudfront_headers_lambda_policy.arn
}

#IAM roles and policies for S3 Bucket Replication

data "aws_iam_policy_document" "cloudfront_bucket_replicator_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudfront_bucket_replicator_role" {
  name_prefix        = "FilmDropCloudFrontBucketReplicatorRole"
  assume_role_policy = data.aws_iam_policy_document.cloudfront_bucket_replicator_assume_role.json
}

data "aws_iam_policy_document" "cloudfront_bucket_replicator" {
  statement {
    sid    = "ReplicationSourceBucketAccess"
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ReplicationSourceObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ReplicationDestinationAccess"
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]

    resources = [
      "arn:aws:s3:::${var.filmdrop_archive_bucket_name}/cloudfront*",
      "arn:aws:s3:::${var.create_log_bucket ? aws_s3_bucket.log_bucket[0].id : var.log_bucket_name}/cloudfront*",
    ]
  }
}

resource "aws_iam_policy" "cloudfront_bucket_replicator_policy" {
  name_prefix = "FilmDropCloudFrontBucketReplicatorPolicy"
  policy      = data.aws_iam_policy_document.cloudfront_bucket_replicator.json
}

resource "aws_iam_role_policy_attachment" "cloudfront_bucket_replicator" {
  role       = aws_iam_role.cloudfront_bucket_replicator_role.name
  policy_arn = aws_iam_policy.cloudfront_bucket_replicator_policy.arn
}
