resource "aws_kinesis_firehose_delivery_stream" "waf_cf_logging_firehose_stream" {
  name        = "aws-waf-logs-cloudfront-${var.waf_appendix}"
  destination = "s3"

  s3_configuration {
    role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/filmdrop/system/FilmDropWAFLoggingFirehose${var.waf_appendix}"
    bucket_arn = "arn:aws:s3:::${var.logging_bucket_name}"
    prefix     = "cloudfront_waf/AWSLogs/${data.aws_caller_identity.current.account_id}/"
  }

}
