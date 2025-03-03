data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name

  # All Cirrus-managed resources will be prefixed with this identifier
  # TODO - CVG - resource naming - temporarily removing resource prefix of 'fd-'
  cirrus_prefix = lower(substr(replace("${var.project_name}-${var.environment}-cirrus", "_", "-"), 0, 63))

  # Use a custom Cirrus Lambda Dist ZIP or accept the module's builtin version
  cirrus_lambda_zip_filepath = (
    var.cirrus_lambda_zip_filepath != null
    ? "${path.root}/${var.cirrus_lambda_zip_filepath}"
    : "${path.module}/cirrus-lambda-dist.zip"
  )
}