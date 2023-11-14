resource "aws_s3_bucket_policy" "cloudfront_custom_error_policy" {
  bucket = aws_s3_bucket.error_bucket.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS":  [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "${var.cloudfront_origin_access_identity_arn}"
          ]
        },
        "Action": "s3:GetObject*",
        "Resource": "${aws_s3_bucket.error_bucket.arn}/*"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "AWS":  [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "${var.cloudfront_origin_access_identity_arn}"
          ]
        },
        "Action": "s3:ListBucket",
        "Resource": "${aws_s3_bucket.error_bucket.arn}"
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
            "${var.cloudfront_origin_access_identity_arn}"
          ]
        },
        "Action": "s3:PutObject*",
        "Resource": "${aws_s3_bucket.error_bucket.arn}/*"
      }
  ]
}
EOF

}
