data "aws_caller_identity" "current" {
}

locals {
  content_pages_id = "filmdrop-${var.website_name}-${var.logging_origin_id}"
}
