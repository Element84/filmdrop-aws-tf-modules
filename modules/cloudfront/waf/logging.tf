resource "aws_kinesis_firehose_delivery_stream" "fd_waf_cf_logging_firehose_stream" {
  name        = "aws-waf-logs-cloudfront-${var.cf_origin_appendix}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.fd_waf_logging_firehose_role.arn
    bucket_arn = "arn:aws:s3:::${var.logging_bucket_name}"
    prefix     = "waf/AWSLogs/${data.aws_caller_identity.current.account_id}/"
  }

}
