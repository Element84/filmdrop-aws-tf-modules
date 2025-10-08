output "role_name" {
  value = aws_iam_role.lambda.name
}

output "function_name" {
  value = aws_lambda_function.func.function_name
}
