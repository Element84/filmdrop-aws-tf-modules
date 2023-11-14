#Security group for VPC endpoints
resource "aws_security_group" "sg_vpcendpoint" {
  name        = "filmdrop-sg-vpcendpoints"
  description = "Allow access to VPC endpoints"
  vpc_id      = aws_vpc.main_vpc.id

  dynamic ingress {
    for_each = var.sg_vpcendpoint_map["ingress"]

    content {
          description      = ingress.value.description
          from_port        = ingress.value.from_port
          to_port          = ingress.value.to_port
          protocol         = ingress.value.protocol
          cidr_blocks      = [aws_vpc.main_vpc.cidr_block]
    }
  }

  dynamic egress {
    for_each = var.sg_vpcendpoint_map["egress"]
    
    content {
          from_port        = egress.value.from_port
          to_port          = egress.value.to_port
          protocol         = egress.value.protocol
          cidr_blocks      = egress.value.cidr_blocks
    }
  }

  tags = merge({ "Name" = "filmdrop-sg-vpcendpoints" }, var.base_tags )
}