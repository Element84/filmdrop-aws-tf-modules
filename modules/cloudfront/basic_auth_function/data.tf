data "aws_region" "current" {
}

data "template_file" "basic_auth_lambda_template" {
  template = file("${path.module}/lambda/index.js")

  vars = {
    KEY_VALUE_STORE_ID = split("/", aws_cloudfront_key_value_store.basicauth_key_value_store.arn)[1]
  }
}
