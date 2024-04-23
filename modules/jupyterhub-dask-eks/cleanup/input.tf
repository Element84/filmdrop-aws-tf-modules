variable "analytics_cluster_name" {
  description = "FilmDrop Analytics EKS Cluster name"
  type        = string
}

variable "analytics_cleanup_stage" {
  description = "FilmDrop Analytics stage name (dev/prod)"
  type        = string
}

variable "analytics_asg_min_capacity" {
  description = "FilmDrop Analytics ASG min capacity"
  type        = number
  default     = 1
}

variable "analytics_node_limit" {
  description = "FilmDrop Analytics node limit for normal usage"
  type        = number
  default     = 4
}

variable "analytics_notifications_schedule_expressions" {
  description = "FilmDrop Analytics notification scheduled expressions"
  type        = list(string)
  default     = ["cron(0 14 * * ? *)", "cron(0 22 * * ? *)"]
}

variable "analytics_cleanup_schedule_expressions" {
  description = "FilmDrop Analytics cleanup scheduled expressions"
  type        = list(string)
  default     = ["cron(0 5 * * ? *)"]
}
