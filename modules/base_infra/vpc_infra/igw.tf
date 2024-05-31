# Creates Internet Gateway, with a public route table, and a default route
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.filmdrop_vpc.id

  tags = {
    Name = "${local.name_prefix}-internet-gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.filmdrop_vpc.id

  tags = {
    Name = "${local.name_prefix}-public-route-table"
  }
}

resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_route_table_associations" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}
