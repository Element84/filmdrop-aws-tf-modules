resource "aws_eip" "eips" {
  for_each = var.public_subnets_az_to_id_map

  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "ngws" {
  for_each = aws_subnet.public_subnets

  allocation_id = element(values(aws_eip.eips)[*].id, index(values(aws_subnet.public_subnets)[*].id, each.value.id))
  subnet_id     = each.value.id
  tags = {
    Name = "${local.name_prefix}-nat-gateway-${each.value.id}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# We need a different route table per subnet, because each subnet
# may point to a different NAT Gateway for high availability
resource "aws_route_table" "private_route_tables" {
  for_each = aws_subnet.private_subnets

  vpc_id = aws_vpc.filmdrop_vpc.id

  tags = {
    Name = "${local.name_prefix}-private-route-table-${each.value.id}"
  }

  depends_on = [aws_nat_gateway.ngws]
}

resource "aws_route_table_association" "private_route_table_associations" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = element(values(aws_route_table.private_route_tables)[*].id, index(values(aws_subnet.private_subnets)[*].id, each.value.id))
}


# While mapping each private subnet route table to a specific NAT Gateway
# we need to consider NAT Gateways are dependent on the number of Public Subnets
# and the number of Public Subnets may not be equal to the number of Private Subnets.
# This means that the number of NAT Gateways may not be equal to the number of Private Route Tables.
resource "aws_route" "private_subnet_default_routes" {
  for_each = aws_subnet.private_subnets

  route_table_id         = element(values(aws_route_table.private_route_tables)[*].id, index(values(aws_subnet.private_subnets)[*].id, each.value.id))
  nat_gateway_id         = element(values(aws_nat_gateway.ngws)[*].id, index(values(aws_subnet.private_subnets)[*].id, each.value.id) % length(values(aws_subnet.public_subnets)[*].id))
  destination_cidr_block = "0.0.0.0/0"
}
