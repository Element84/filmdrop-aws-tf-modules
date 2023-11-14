resource "aws_iam_role" "analytics_eks_codebuild_iam_role" {
  name_prefix = "analytics-eks-codebuild-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "events.amazonaws.com",
          "codebuild.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "analytics_eks_codebuild_iam_policy" {
  role = aws_iam_role.analytics_eks_codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CodeBuildAnalyticsPolicy",
            "Effect": "Allow",
            "Action": [
                "acm:*",
                "waf:*",
                "codebuild:*",
                "eks:*",
                "kms:*",
                "iam:*",
                "ecr:*",
                "cloudfront:*",
                "iam:*",
                "lambda:*",
                "sns:*",
                "ssm:*",
                "s3:*",
                "firehose:*",
                "logs:*",
                "ec2:*",
                "es:*",
                "sqs:*",
                "apigateway:*",
                "cognito-idp:*",
                "dynamodb:*",
                "wafv2:*",
                "cloudfront:*",
                "cloudformation:*",
                "route53:*",
                "events:*",
                "ecs:*",
                "ecr:*",
                "cloudwatch:*",
                "sts:Decode*"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role" "cloudfront_origin_lambda_role" {
  name = "FilmDropCfOrigin${var.cloudfront_distribution_id}"

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

resource "aws_iam_policy" "cloudfront_origin_lambda_policy" {
  name        = "FilmDropCfOrigin${var.cloudfront_distribution_id}"
  description = "Policy allowing Lambda to Update CloudFront Custom Origin"

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

resource "aws_iam_role_policy_attachment" "cloudfront_origin_lambda" {
  role       = aws_iam_role.cloudfront_origin_lambda_role.name
  policy_arn = aws_iam_policy.cloudfront_origin_lambda_policy.arn
}
