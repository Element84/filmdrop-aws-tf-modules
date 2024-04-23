resource "aws_iam_role" "analytics_cleanup_lambda_role" {
  name_prefix = "${var.analytics_cluster_name}-"

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

resource "aws_iam_policy" "analytics_cleanup_lambda_policy" {
  name_prefix = "${var.analytics_cluster_name}-"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:*",
                "ec2:*",
                "cloudwatch:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:Get*",
                "sns:List*",
                "sns:Publish"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "analytics_cleanup_lambda_policy_attachment" {
  role       = aws_iam_role.analytics_cleanup_lambda_role.name
  policy_arn = aws_iam_policy.analytics_cleanup_lambda_policy.arn
}
