resource "aws_lambda_function" "cloudfront_headers_lambda" {
  filename         = data.archive_file.cloudfront_headers_lambda_zip.output_path
  source_code_hash = data.archive_file.cloudfront_headers_lambda_zip.output_base64sha256
  function_name    = "${local.origin_id_prefix}-headers"
  role             = aws_iam_role.cloudfront_headers_lambda_role.arn
  description      = "Sets CloudFront Custom Headers"
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  timeout          = "60"

  environment {
    variables = {
      DISTRIBUTIONID           = aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.id
      FORWARDEDHOST            = length(var.domain_aliases) > 0 ? element(concat(var.domain_aliases, [""]), 0) : aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.domain_name
      FORWARDEDPROTO           = "https"
      AUTHKEYNAME              = var.auth_header_name
      AUTHKEYVALUE             = var.auth_header_value
      REGION                   = data.aws_region.current.name
      SSM_FORWARDED_HOST_PARAM = aws_ssm_parameter.cloudfront_x_forwarded_host.name
    }
  }
}

# Run only if CloudFront Distribution is newely created
resource "null_resource" "update_cloudfront_headers" {
  triggers = {
    cloudfront_domain_name = aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.domain_name
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Update CloudFront Headers."
aws lambda invoke --function-name ${aws_lambda_function.cloudfront_headers_lambda.function_name} --payload '{ }' output

EOF

  }

  depends_on = [
    aws_lambda_function.cloudfront_headers_lambda,
    aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution,
    aws_ssm_parameter.cloudfront_x_forwarded_host
  ]
}

resource "aws_ssm_parameter" "cloudfront_x_forwarded_host" {
  name  = "${local.origin_id_prefix}-dns"
  type  = "String"
  value = length(var.domain_aliases) > 0 ? element(concat(var.domain_aliases, [""]), 0) : var.domain_name == "" ? "tmp.filmdrop.io" : var.domain_name

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
