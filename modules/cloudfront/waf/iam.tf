# Define role to log WAF Requests - Role is specific to each Cloudfront WAF
resource "aws_iam_role" "fd_waf_logging_firehose_role" {
  name_prefix = "FilmDropWAFLog${local.origin_appendix}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

# Policies for allowing Cloudfront WAF logging capabiliites
resource "aws_iam_policy" "fd_waf_logging_firehose_policy" {
  name_prefix = "FilmDropWAFLog${local.origin_appendix}"
  description = "IAM Policy to allow firehose to log cloudfront waf"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "glue:GetTableVersions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.logging_bucket_name}",
        "arn:aws:s3:::${var.logging_bucket_name}/*"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration"
      ],
      "Resource": "arn:aws:lambda:us-east-1:252208689150:function:%FIREHOSE_DEFAULT_FUNCTION%:%FIREHOSE_DEFAULT_VERSION%"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:us-east-1:252208689150:log-group:/aws/kinesisfirehose/aws-waf-logs-cloudfront-${local.origin_appendix}:log-stream:*"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords"
      ],
      "Resource": "arn:aws:kinesis:us-east-1:252208689150:stream/%FIREHOSE_STREAM_NAME%"
    },
    {
      "Effect": "Allow",
      "Action": [
          "kms:Decrypt"
      ],
      "Resource": [
          "arn:aws:kms:us-east-1:252208689150:key/%SSE_KEY_ID%"
      ],
      "Condition": {
          "StringEquals": {
              "kms:ViaService": "kinesis.%REGION_NAME%.amazonaws.com"
          },
          "StringLike": {
              "kms:EncryptionContext:aws:kinesis:arn": "arn:aws:kinesis:%REGION_NAME%:252208689150:stream/%FIREHOSE_STREAM_NAME%"
          }
      }
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "fd_waf_logging_firehose_policy_attachment" {
  role       = aws_iam_role.fd_waf_logging_firehose_role.name
  policy_arn = aws_iam_policy.fd_waf_logging_firehose_policy.arn
}

