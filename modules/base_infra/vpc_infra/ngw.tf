
#build a map with general and prod like subnet availability zones
locals {
    prod_like_and_general_az_map = {
            "general" = var.ngw_general_subnet_az
            "prod-like" = var.ngw_prodlike_subnet_az
    }

    general_az_map = {
        "general" = var.ngw_general_subnet_az
    }
}

#Add EIPS with the respective maps of prodlike or general
resource "aws_eip" "eips" {
    for_each = var.is_prod_like ? local.prod_like_and_general_az_map : local.general_az_map
    vpc = true
    depends_on = [ aws_internet_gateway.igw ]

}

#Add NAT Gateway
resource "aws_nat_gateway" "ngws" {
    for_each = var.is_prod_like ? local.prod_like_and_general_az_map : local.general_az_map

    allocation_id = aws_eip.eips[each.key].id
    subnet_id = aws_subnet.pub_subnets[each.value].id

    tags = merge({ "Name" = "filmdrop-nat-gateway-${each.key}" }, var.base_tags )

    depends_on = [ aws_internet_gateway.igw ]
} 

#Route table
resource "aws_route_table" "nat_route_tables" {
    for_each = var.is_prod_like ? local.prod_like_and_general_az_map : local.general_az_map
    vpc_id = aws_vpc.main_vpc.id

    tags = merge({ "Name" = "filmdrop-private-route-table" }, var.base_tags )

    depends_on = [aws_nat_gateway.ngws]
}

#Add RT association
resource "aws_route_table_association" "nat_rt_association" {
    for_each = var.is_prod_like ? local.prod_like_and_general_az_map : local.general_az_map

    subnet_id = aws_subnet.pri_subnets[each.value].id
    route_table_id = aws_route_table.nat_route_tables[each.key].id
}

#Add routes
resource "aws_route" "nat_routes" {
    for_each = var.is_prod_like ? local.prod_like_and_general_az_map : local.general_az_map

    route_table_id = aws_route_table.nat_route_tables[each.key].id
    nat_gateway_id = aws_nat_gateway.ngws[each.key].id
    destination_cidr_block = local.all_cidr

}

#Add peering route
resource "aws_route" "nat_peering_routes" {
    for_each = var.is_peered ? local.general_az_map : {}

    route_table_id = aws_route_table.nat_route_tables[each.key].id
    destination_cidr_block = var.vpc_peer_cidr
    vpc_peering_connection_id = var.vpc_peering_connection_id

}