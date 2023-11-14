#Add vpc
resource "aws_vpc" "main_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = merge({ "Name" = var.vpc_name }, var.base_tags )
}


#Add public subnets
resource "aws_subnet" "pub_subnets" {
    for_each = var.public_subnets_cidr_map

    vpc_id = aws_vpc.main_vpc.id
    cidr_block = each.value
    availability_zone = each.key

    tags = merge({ "Name" = "filmdrop-public-snet-${each.key}" }, var.base_tags )

} 

#Add private subnets
resource "aws_subnet" "pri_subnets" {
    for_each = var.private_subnets_cidr_map

    vpc_id = aws_vpc.main_vpc.id
    cidr_block = each.value
    availability_zone = each.key

    tags = merge({ "Name" = "filmdrop-private-snet-${each.key}" }, var.base_tags )

} 

#Enable VPC flow logs
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_s3_bucket.vpc_log_bucket.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main_vpc.id
}
