data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_subnet" "selected" {
  count = length(var.vpc_subnet_ids)

  id = var.vpc_subnet_ids[count.index]
}

locals {
  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name
}
