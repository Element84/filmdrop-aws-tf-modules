resource "aws_iam_role" "analytics_eks_codebuild_iam_role" {
  name = "analytics-eks-codebuild-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
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