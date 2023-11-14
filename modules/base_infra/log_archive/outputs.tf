output "s3_access_log_bucket" {
  value = aws_s3_bucket.s3_access_logs_bucket.id
}

output "s3_logs_archive_bucket" {
  value = aws_s3_bucket_versioning.s3_logs_archive_bucket_versioning.id
}

output "s3_access_log_bucket_domain_name" {
  value = aws_s3_bucket.s3_access_logs_bucket.bucket_domain_name
}

output "s3_logs_archive_bucket_domain_name" {
  value = aws_s3_bucket.s3_logs_archive_bucket.bucket_domain_name
}
