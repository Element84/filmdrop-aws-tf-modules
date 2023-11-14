
resource "aws_wafv2_web_acl_logging_configuration" "wafv2_logging_configuration" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.wafv2_logging_firehose_stream.arn]
  resource_arn            = var.web_acl_arn
}

resource "aws_kinesis_firehose_delivery_stream" "wafv2_logging_firehose_stream" {
  name        = "aws-waf-logs-cloudfront-${local.valid_web_acl_name}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.waf_logging_firehose_role.arn
    bucket_arn = "arn:aws:s3:::${var.filmdrop_archive_bucket_name}"
    prefix     = "cloudfront_waf/AWSLogs/${data.aws_caller_identity.current.account_id}/"
  }
}
