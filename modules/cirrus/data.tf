locals {
  cirrus_prefix = lower(substr(replace("fd-${var.project_name}-${var.environment}-cirrus", "_", "-"), 0, 63))
}
