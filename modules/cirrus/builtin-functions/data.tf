data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_subnets" "selected" {
  filter {
    name   = "subnet-id"
    values = var.vpc_subnet_ids
  }
}

data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.selected.ids)

  id = each.value
}
