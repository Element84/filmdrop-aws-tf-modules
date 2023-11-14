resource "aws_iam_service_linked_role" "service_linked_role" {
    aws_service_name = var.aws_service_name
    description = "FilmDrop Service Linked Role for ${var.aws_service_name}"

    tags = {
        Name = "filmdrop-linked-role-${var.aws_service_name}"
    }
}
