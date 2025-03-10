resource "aws_wafv2_web_acl_logging_configuration" "wafv2_logging_configuration" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.fd_waf_cf_logging_firehose_stream.arn]
  resource_arn            = aws_wafv2_web_acl.fd_waf_acl.arn
}

resource "aws_kinesis_firehose_delivery_stream" "fd_waf_cf_logging_firehose_stream" {
  name        = "aws-waf-logs-cloudfront-${local.origin_appendix}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.fd_waf_logging_firehose_role.arn
    bucket_arn = "arn:aws:s3:::${var.logging_bucket_name}"
    prefix     = "waf/AWSLogs/${data.aws_caller_identity.current.account_id}/"
  }

}
