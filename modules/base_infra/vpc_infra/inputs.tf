variable vpc_cidr {}
variable public_subnets_cidr_map {}
variable private_subnets_cidr_map {}
variable base_tags {}
variable vpc_name { default = "filmdrop-vpc"}



variable "ngw_general_subnet_az" {}
variable "ngw_prodlike_subnet_az" {}
variable "is_prod_like" {}
variable "gateway_endpoints_list" {
    default = ["s3", "dynamodb"]
}

variable "interface_endpoints_map" {
    default = ["secretsmanager", "ec2","sts"]
}

variable sg_vpcendpoint_map {
    default = {
        "ingress" = [
            {
            "description" = "Allow access for vpc endpoints"
            "from_port" = 0
            "to_port" = 65535
            "protocol" = "tcp"
            }
        ]
        "egress" = [
            {
            "from_port" = 0
            "to_port" = 65535
            "protocol" = "tcp"
            "cidr_blocks" = ["0.0.0.0/0"]
            }
        ]
    }

}

variable "is_peered" {}
variable vpc_peer_cidr {}
variable "vpc_peering_connection_id" {}
variable "waf_buckets_map" {}
variable "linked_role_services_list" {
    default = ["es.amazonaws.com"]
}

locals {
    all_cidr = "0.0.0.0/0"
}