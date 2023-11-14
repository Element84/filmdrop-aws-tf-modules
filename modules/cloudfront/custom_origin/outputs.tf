output "cloudfront_origin_access_identity_arn" {
  value = aws_cloudfront_origin_access_identity.filmdrop_origin_access_identity.iam_arn
}

output "cloudfront_access_identity_path" {
  value = aws_cloudfront_origin_access_identity.filmdrop_origin_access_identity.cloudfront_access_identity_path
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.id
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.domain_name
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.arn
}

output "cloudfront_distribution_zone" {
  value = aws_cloudfront_distribution.filmdrop_managed_cloudfront_distribution.hosted_zone_id
}

output "cloudfront_domain_origin_param" {
  value = aws_ssm_parameter.cloudfront_custom_origin.name
}
