output "cirrus_dashboard_url" {
  value = "https://${module.cloudfront_s3_website.domain_name}"
}
