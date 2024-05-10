data "aws_caller_identity" "current" {
}

data "aws_canonical_user_id" "current" {
}

data "aws_region" "current" {
}

locals {
  origin_id_prefix = lower(substr(replace("fd-${var.project_name}-${var.environment}-${var.application_name}", "_", "-"), 0, 63))
}
