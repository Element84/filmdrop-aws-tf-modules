#Output nat gateway ids as a map
output "nat_gateway" {
  description = "Nat Gateway"
  value       = {
    for az, ngw in aws_nat_gateway.ngws : az => ngw.id
  }
}

#output eips as a map
output "gateway_eips" {
  description = "Gateway EIPs"
  value = {
    for k, eip in aws_eip.eips : k => eip.id
  }
  
}

#Vpc id output
output "vpc_id" {
  description = "ID of the VPC"
  value = aws_vpc.main_vpc.id
}

#private subnets output 
output "private_subnets" {
  description = "ID of Private Subnets"
  value = {
    for az, pri_subnets in aws_subnet.pri_subnets : az => pri_subnets.id
  }

}

#public subnets output
output "public_subnets" {
  description = "ID of Public Subnets"
  value = {
    for az, pub_subnets in aws_subnet.pub_subnets : az => pub_subnets.id
  }
}

output "security_group_id" {
  description = "ID of Security Group"
  value = aws_security_group.sg_vpcendpoint.id
}

output "vpc_cidr" {
  description = "VPC CIDR Range"
  value = var.vpc_cidr
}
