# Create basic authentication cloudfront function
resource "aws_cloudfront_function" "basicauth_cf_function" {
  name                         = "${var.origin_id_prefix}-basicauth-function"
  runtime                      = "cloudfront-js-2.0"
  comment                      = "CloudFront function with BasicAuth mechanism"
  publish                      = true
  code                         = data.template_file.basic_auth_lambda_template.rendered
  key_value_store_associations = [aws_cloudfront_key_value_store.basicauth_key_value_store.arn]
}

resource "aws_cloudfront_key_value_store" "basicauth_key_value_store" {
  name    = "${var.origin_id_prefix}-basicauth-kvs"
  comment = "KeyValueStore for BasicAuth CloudFront function"
}
