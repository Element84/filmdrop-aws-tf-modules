# Default FilmDrop VPC Security Group
resource "aws_security_group" "filmdrop_vpc_default_sg" {
  name        = "${local.name_prefix}-sg"
  description = "Default Security Group for the FilmDrop ${var.project_name} ${var.environment} VPC"
  vpc_id      = aws_vpc.filmdrop_vpc.id
}

# Allows any inbound traffic coming from within the FilmDrop VPC
resource "aws_security_group_rule" "filmdrop_vpc_ingress_rule" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.filmdrop_vpc_default_sg.id
}

# Allows any outbound traffic exiting the FilmDrop VPC
resource "aws_security_group_rule" "filmdrop_vpc_egress_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.filmdrop_vpc_default_sg.id
}
