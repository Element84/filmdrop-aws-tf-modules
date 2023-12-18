data "aws_vpc" "vpc" {
  tags = var.vpc_tags
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = var.private_subnet_tags
}

data "aws_subnet" "private_subnets" {
  for_each = toset(data.aws_subnets.private.ids)

  vpc_id = data.aws_vpc.vpc.id
  id     = each.value
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = var.public_subnet_tags
}

data "aws_subnet" "public_subnets" {
  for_each = toset(data.aws_subnets.public.ids)

  vpc_id = data.aws_vpc.vpc.id
  id     = each.value
}

data "aws_security_group" "security_group" {
  vpc_id = data.aws_vpc.vpc.id

  filter {
    name   = "group-name"
    values = [var.security_group_name]
  }
}
