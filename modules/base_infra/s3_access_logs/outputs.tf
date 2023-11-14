output "s3_access_log_bucket" {
  value = aws_s3_bucket.s3_access_logs_bucket.id
}
