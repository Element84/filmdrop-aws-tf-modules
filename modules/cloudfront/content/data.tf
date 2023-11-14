data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

locals {
  content_pages_id  = "filmdrop-${var.website_name}-${var.logging_origin_id}"
}
