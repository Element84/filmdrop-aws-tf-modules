output "log_bucket" {
  value = var.create_log_bucket ? local.log_bucket : var.log_bucket_name
}

output "log_bucket_domain_name" {
  value = var.create_log_bucket ? local.log_bucket_domain_name : var.log_bucket_domain_name
}

output "origin_id" {
  value = local.origin_id
}

output "cloudfront_origin_access_identity_arn" {
  value = aws_cloudfront_origin_access_identity.filmdrop_origin_access_identity.iam_arn
}

output "cloudfront_access_identity_path" {
  value = aws_cloudfront_origin_access_identity.filmdrop_origin_access_identity.cloudfront_access_identity_path
}
