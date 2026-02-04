data "aws_iam_policy_document" "titiler_lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "titiler-lambda-role" {
  name_prefix        = "titiler-lambdaRole"
  assume_role_policy = data.aws_iam_policy_document.titiler_lambda_assume_role.json
}

data "aws_iam_policy_document" "titiler_lambda_policy" {
  dynamic "statement" {
    for_each = length(var.authorized_s3_arns) > 0 ? [1] : []
    content {
      sid       = "AuthorizedS3Access"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = var.authorized_s3_arns
    }
  }
}

resource "aws_iam_role_policy" "titiler-lambda-inline-policy" {
  count  = length(var.authorized_s3_arns) > 0 ? 1 : 0
  name   = "titiler-lambda-inline-policy"
  role   = aws_iam_role.titiler-lambda-role.id
  policy = data.aws_iam_policy_document.titiler_lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.titiler-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.titiler-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
