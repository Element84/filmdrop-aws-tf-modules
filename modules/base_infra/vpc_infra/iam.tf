#Add Service linked roles from the list
resource "aws_iam_service_linked_role" "service_linked_roles" {
    for_each = toset(var.linked_role_services_list)
  
    aws_service_name = each.value
    description = "Service role for ${each.value}"

    tags = merge({ "Name" = "linked-role-${each.value}" }, var.base_tags )
}