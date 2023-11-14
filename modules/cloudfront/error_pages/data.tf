data "aws_caller_identity" "current" {
}

locals {
  error_pages_id = "filmdrop-error-pages-${var.logging_origin_id}"
}
