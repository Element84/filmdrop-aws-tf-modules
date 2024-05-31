module "gateway_endpoints" {
  source = "../vpc_endpoint/gateway_endpoint"

  for_each = toset(var.gateway_endpoints_list)

  vpc_id          = aws_vpc.filmdrop_vpc.id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  route_table_ids = concat([aws_route_table.public_route_table.id], values(aws_route_table.private_route_tables)[*].id)
}

module "interface_endpoints" {
  source = "../vpc_endpoint/interface_endpoint"

  for_each = toset(var.interface_endpoints_list)

  vpc_id              = aws_vpc.filmdrop_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  security_group_ids  = [aws_security_group.filmdrop_vpc_default_sg.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
  private_dns_enabled = true
}
