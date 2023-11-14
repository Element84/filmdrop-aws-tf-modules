data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

locals {
  error_pages_id  = "filmdrop-error-pages-${var.logging_origin_id}"
}
