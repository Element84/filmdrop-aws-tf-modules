output "error_bucket" {
  value = aws_s3_bucket.error_bucket.id
}

output "error_bucket_domain_name" {
  value = aws_s3_bucket.error_bucket.bucket_domain_name
}

output "error_pages_id" {
  value = local.error_pages_id
}
