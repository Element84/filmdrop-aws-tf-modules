output "analytics_url" {
  value = "https://${module.cloudfront_load_balancer_endpoint.domain_name}"
}
