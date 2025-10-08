data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name

  # For determining whether a task image is in ECR.
  # Used in conjunction with `resolve_ecr_tag_to_digest`.
  # Requires `<ECR repository URI>:<tag>` format with no digest.
  ecr_image_regex = "^(?P<registry>(?P<account_id>[0-9]+)\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com)/(?P<repository>[^:]+):(?P<tag>.+)$"
}
