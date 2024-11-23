data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name

  # All Cirrus-managed resources will be prefixed with this identifier
  cirrus_prefix = lower(substr(replace("fd-${var.project_name}-${var.environment}-cirrus", "_", "-"), 0, 63))
}