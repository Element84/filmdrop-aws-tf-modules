
data "aws_caller_identity" "current" {
}

locals {
  origin_appendix = lower(substr(replace(replace("fd-${var.project_name}-${var.environment}", "-", ""), "_", ""), 0, 18))
}