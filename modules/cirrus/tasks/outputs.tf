output "lambda" {
  value = {
    arn = one(aws_lambda_function.task_lambda[*].arn)
    # ... other things that are needed
  }
}

# TODO - CVG - no Batch yet
# output "batch" {
#   value = {
#     arn = one(aws_lambda_function.task_lambda[*].arn)
#     # ... other things that are needed
#   }
# }