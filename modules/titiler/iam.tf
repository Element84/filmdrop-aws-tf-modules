resource "aws_iam_role" "titiler_lambda_role" {
  name_prefix = "titiler-${var.environment}-${data.aws_region.current.name}-lambdaRole"

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

resource "aws_iam_policy" "titiler_lambda_policy" {
  name_prefix = "titiler-${var.environment}-${data.aws_region.current.name}-lambdaPolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": [
                "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/titiler*:*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/titiler*:*:*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "titiler_lambda_vpc_policy_attachment" {
  role       = aws_iam_role.titiler_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "titiler_lambda_base_policy" {
  role       = aws_iam_role.titiler_lambda_role.name
  policy_arn = aws_iam_policy.titiler_lambda_policy.arn
}

resource "aws_iam_role" "titiler_gw_role" {
  name_prefix = "titiler-${var.environment}-${data.aws_region.current.name}-apigwRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "titiler_gw_policy" {
  name_prefix = "titiler-${var.environment}-${data.aws_region.current.name}-apigwPolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:DescribeLogGroups",
              "logs:DescribeLogStreams",
              "logs:PutLogEvents",
              "logs:GetLogEvents",
              "logs:FilterLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "titiler_gw_base_policy" {
  role       = aws_iam_role.titiler_gw_role.name
  policy_arn = aws_iam_policy.titiler_gw_policy.arn
}
