
data "aws_caller_identity" "current" {
}

locals {
  origin_appendix = lower(substr(var.cf_origin_appendix, 0, 18))
}
