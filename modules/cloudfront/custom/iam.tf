#IAM roles and policies for Lambda that Sets CloudFront Custom Headers
resource "aws_iam_role" "cloudfront_headers_lambda_role" {
  name = "FilmDropCloudFront${aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.id}"
  path = "/filmdrop/egress/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "cloudfront_headers_lambda_policy" {
  name        = "FilmDropCloudFront${aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.id}"
  description = "Policy allowing Lambda to Set CloudFront Custom Headers"

  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:*",
                "dynamodb:*",
                "ssm:*",
                "secretsmanager:*",
                "lambda:*",
                "sts:AssumeRole"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cloudfront_header_lambda" {
  role       = aws_iam_role.cloudfront_headers_lambda_role.name
  policy_arn = aws_iam_policy.cloudfront_headers_lambda_policy.arn
}
