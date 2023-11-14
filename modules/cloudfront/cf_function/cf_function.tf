#Create cloudfront function
resource "aws_cloudfront_function" "cf_function" {
  name    = var.name
  runtime = var.runtime
  comment = var.comment
  publish = var.publish
  code    = file(var.code_path)
}