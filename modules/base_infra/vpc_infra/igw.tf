
#Add internet gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id

    tags = merge({ "Name" = "filmdrop-internet-gateway" }, var.base_tags )
}

#Add public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = local.all_cidr
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = merge({ "Name" = "filmdrop-public-route-table" }, var.base_tags )
}

#Add route table association
resource "aws_route_table_association" "public_rt_association" {
  for_each = aws_subnet.pub_subnets

  subnet_id = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}
