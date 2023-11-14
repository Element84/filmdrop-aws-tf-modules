module "service_linked_roles" {
    source = "../service_linked_role"

    for_each = toset(var.linked_role_services_list)
  
    aws_service_name = each.value
}
