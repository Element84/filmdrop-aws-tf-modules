resource "aws_vpc" "filmdrop_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets_az_to_id_map

  vpc_id            = aws_vpc.filmdrop_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-public-subnet-${each.key}"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets_az_to_id_map

  vpc_id            = aws_vpc.filmdrop_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-private-subnet-${each.key}"
  }

}

# Set up default DHCP options for DNS resolution in FilmDrop VPC - defaults to AmazonProvidedDNS
resource "aws_vpc_dhcp_options" "vpc_dhcp_options" {
  domain_name_servers = var.dhcp_options_domain_name_servers
  domain_name         = "${data.aws_region.current.name}.compute.internal"
}

resource "aws_vpc_dhcp_options_association" "vpc_dhcp_options_association" {
  vpc_id          = aws_vpc.filmdrop_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.vpc_dhcp_options.id
}


# Enable VPC flow logs to the FilmDrop Archive bucket
resource "aws_flow_log" "filmdrop_vpc_flow_logs_to_s3" {
  log_destination          = "arn:aws:s3:::${var.archive_log_bucket_name}/vpc-flow-logs/"
  log_destination_type     = "s3"
  log_format               = var.log_format
  max_aggregation_interval = var.max_aggregation_interval
  traffic_type             = var.traffic_type
  vpc_id                   = aws_vpc.filmdrop_vpc.id

  tags = {
    Name = "${local.name_prefix}-flow-logs-${aws_vpc.filmdrop_vpc.id}"
  }
}

moved {
  from = aws_vpc.main_vpc
  to   = aws_vpc.filmdrop_vpc
}

moved {
  from = aws_subnet.pub_subnets
  to   = aws_subnet.public_subnets
}

moved {
  from = aws_subnet.pri_subnets
  to   = aws_subnet.private_subnets
}
