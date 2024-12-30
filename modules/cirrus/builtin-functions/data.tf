data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_subnet" "selected" {
  for_each = toset(var.vpc_subnet_ids)

  id = each.value
}