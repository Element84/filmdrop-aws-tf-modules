data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_subnet" "selected" {
  count = length(var.vpc_subnet_ids)

  id = var.vpc_subnet_ids[count.index]
}
