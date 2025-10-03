# FEEDER LAMBDA IAM ROLE -- BASIC SETUP
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "feeder_lambda_assume_role" {
  statement {
    sid     = "LambdaServiceAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    # Conditions to prevent the "confused deputy" security problem
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:lambda:${local.current_region}:${local.current_account}:function:${local.name_main}"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

resource "aws_iam_role" "feeder_lambda" {
  name               = local.name_main
  description        = "Lambda execution role for Cirrus Feeder '${var.feeder_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.feeder_lambda_assume_role.json
}
# ==============================================================================

# FEEDER LAMBDA FUNCTION -- REMOTE ZIP, LOCAL ZIP, OR IMAGE BASED
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "feeder" {
  function_name = local.name_main

  role         = aws_iam_role.feeder_lambda.arn
  package_type = "Zip"
  handler      = var.feeder_config.lambda.handler
  runtime      = var.feeder_config.lambda.runtime


  # Local ZIP handling.
  # Path is expected to be relative to the ROOT module of this deployment.
  filename = (
    var.feeder_config.lambda.filename != null
    ? "${path.root}/${var.feeder_config.lambda.filename}"
    : null
  )
}
# ==============================================================================
