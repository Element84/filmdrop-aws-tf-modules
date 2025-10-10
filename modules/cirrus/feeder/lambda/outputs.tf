output "role_name" {
  description = <<-DESCRIPTION
  Lambda role name.
  DESCRIPTION

  value = aws_iam_role.lambda.name
}

output "function_name" {
  description = <<-DESCRIPTION
  Lambda function name.
  DESCRIPTION

  value = aws_lambda_function.func.function_name
}

