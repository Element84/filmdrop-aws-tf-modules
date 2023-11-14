output "certificate_arn" {
  description = "FilmDrop Analytics ELB certificate ARN"
  value       = var.domain_alias == "" ? "" : module.analytics_certificate[0].certificate_arn
}
