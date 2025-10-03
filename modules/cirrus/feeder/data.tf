data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_main = lower("${var.resource_prefix}-feeder-${var.feeder_config.name}")

  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name
}
