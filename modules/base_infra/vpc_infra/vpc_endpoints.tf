#Add gateway endpoints
resource "aws_vpc_endpoint" "gateway_endpoints" {
  for_each = toset(var.gateway_endpoints_list)

  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat([aws_route_table.public_route_table.id], values(aws_route_table.nat_route_tables).*.id )

  tags = merge({ "Name" = "vpc-endpoint-${each.value}" }, var.base_tags )
}

#Add interface endpoints
resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = toset(var.interface_endpoints_map)

  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sg_vpcendpoint.id
  ]

  private_dns_enabled = true
  tags = merge({ "Name" = "vpc-endpoint-${each.value}" }, var.base_tags )
}
