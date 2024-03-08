# Create basic authentication cloudfront function
resource "aws_cloudfront_function" "basicauth_cf_function" {
  name    = "${var.origin_id_prefix}-basicauth-function"
  runtime = "cloudfront-js-2.0"
  comment = "CloudFront function with BasicAuth mechanism"
  publish = true
  code    = data.template_file.basic_auth_lambda_template.rendered
}

resource "aws_cloudfront_key_value_store" "basicauth_key_value_store" {
  name    = "${var.origin_id_prefix}-basicauth-kvs"
  comment = "KeyValueStore for BasicAuth CloudFront function"
}

resource "null_resource" "update_cloudfront_headers" {
  triggers = {
    basicauth_cf_function     = aws_cloudfront_function.basicauth_cf_function.arn
    basicauth_key_value_store = aws_cloudfront_key_value_store.basicauth_key_value_store.arn
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Updating BasicAuth CloudFront Function KeyValueStore association."
export BASICAUTHETAG=`aws cloudfront get-function --name ${var.origin_id_prefix}-basicauth-function cf_basicauth_function_out1.js | jq '.ETag' | tr -d \"`
aws cloudfront update-function --name ${var.origin_id_prefix}-basicauth-function --function-config Comment="CloudFront function with BasicAuth mechanism",Runtime="cloudfront-js-2.0",KeyValueStoreAssociations="{Quantity=1,Items=[{KeyValueStoreARN='${aws_cloudfront_key_value_store.basicauth_key_value_store.arn}'}]}" --function-code fileb://cf_basicauth_function_out1.js --if-match $BASICAUTHETAG

sleep 60
export BASICAUTHPUBLISHETAG=`aws cloudfront get-function --name ${var.origin_id_prefix}-basicauth-function cf_basicauth_function_out2.js | jq '.ETag' | tr -d \"`
aws cloudfront publish-function --name ${var.origin_id_prefix}-basicauth-function --if-match $BASICAUTHPUBLISHETAG

EOF

  }

  depends_on = [
    aws_cloudfront_function.basicauth_cf_function,
    aws_cloudfront_key_value_store.basicauth_key_value_store
  ]
}
