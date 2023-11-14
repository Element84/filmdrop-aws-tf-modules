output "content_bucket" {
  value = aws_s3_bucket.content_bucket.id
}

output "content_bucket_arn" {
  value = aws_s3_bucket.content_bucket.arn
}

output "content_bucket_domain_name" {
  value = aws_s3_bucket.content_bucket.bucket_domain_name
}

output "content_bucket_regional_domain_name" {
  value = aws_s3_bucket.content_bucket.bucket_regional_domain_name
}
