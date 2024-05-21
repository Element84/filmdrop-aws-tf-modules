resource "aws_codebuild_project" "console_ui_codebuild" {
  name           = "console-ui-build-${random_id.suffix.hex}"
  description    = "Builds FilmDrop Console UI"
  build_timeout  = "480"
  queued_timeout = "480"
  service_role   = aws_iam_role.console_ui_codebuild_iam_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "FILMDROP_UI_TAG"
      value = var.filmdrop_ui_release_tag
    }

    environment_variable {
      name  = "FILMDROP_UI_CONFIG"
      value = var.filmdrop_ui_config
    }

    environment_variable {
      name  = "FILMDROP_UI_LOGO_FILE"
      value = var.filmdrop_ui_logo_file
    }

    environment_variable {
      name  = "FILMDROP_UI_LOGO"
      value = var.filmdrop_ui_logo
    }

    environment_variable {
      name  = "CONTENT_BUCKET"
      value = var.console_ui_bucket_name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/filmdrop/console_ui_build"
      stream_name = "console-ui-build"
    }
  }

  source {
    type     = "S3"
    location = "${aws_s3_bucket.console_ui_source_config.arn}/"
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.vpc_private_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  depends_on = [
    aws_s3_bucket.console_ui_source_config,
    aws_s3_object.console_ui_build_spec
  ]
}

resource "null_resource" "trigger_console_ui_upgrade" {
  triggers = {
    new_codebuild           = aws_codebuild_project.console_ui_codebuild.id
    region                  = data.aws_region.current.name
    account                 = data.aws_caller_identity.current.account_id
    filmdrop_ui_release_tag = var.filmdrop_ui_release_tag
    filmdrop_ui_config      = var.filmdrop_ui_config
    console_ui_bucket_name  = var.console_ui_bucket_name
    new_source              = aws_s3_bucket.console_ui_source_config.id
    new_build_spec          = aws_s3_object.console_ui_build_spec.etag
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Triggering CodeBuild Project."
START_RESULT=$(aws codebuild start-build --project-name ${aws_codebuild_project.console_ui_codebuild.id})
BUILD_ID=$(echo $START_RESULT | jq '.build.id' -r)

BUILD_STATUS="IN_PROGRESS"
while [[ "$BUILD_STATUS" == "IN_PROGRESS" ]]; do
    sleep 5
    BUILD=$(aws codebuild batch-get-builds --ids $BUILD_ID)
    BUILD_STATUS=$(echo $BUILD | jq '.builds[0].buildStatus' -r)
    if [[ "$BUILD_STATUS" == "IN_PROGRESS" ]]; then
        echo "CodeBuild is still in progress..."
    fi
done

if [[ "$BUILD_STATUS" != "SUCCEEDED" ]]; then
    LOG_URL=$(echo $BUILD | jq '.builds[0].logs.deepLink' -r)
    echo "Build failed - logs are available at [$LOG_URL]"
    exit 1
else
    echo "console UI CodeBuild succeeded"
fi
EOF
  }

  depends_on = [
    aws_s3_bucket.console_ui_source_config,
    aws_s3_object.console_ui_build_spec,
    aws_codebuild_project.console_ui_codebuild
  ]
}

resource "random_id" "suffix" {
  byte_length = 8
}

resource "aws_s3_bucket" "console_ui_source_config" {
  bucket        = "console-ui-config-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "console_ui_source_config_ownership_controls" {
  bucket = aws_s3_bucket.console_ui_source_config.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "console_ui_source_config_public_access_block" {
  bucket = aws_s3_bucket.console_ui_source_config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "console_ui_source_config_versioning" {
  bucket = aws_s3_bucket.console_ui_source_config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "console_ui_build_spec" {
  bucket = aws_s3_bucket.console_ui_source_config.id
  key    = "buildspec.yml"
  source = "${path.module}/buildspec.yml"
  etag   = filemd5("${path.module}/buildspec.yml")
}

resource "null_resource" "cleanup_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.console_ui_source_config.id
    region      = data.aws_region.current.name
    account     = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "FilmDrop CloudFront bucket has been created."

aws s3 ls s3://${self.triggers.bucket_name}
EOF

  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "Cleaning FilmDrop bucket."

aws s3 rm s3://${self.triggers.bucket_name}/ --recursive
EOF
  }


  depends_on = [
    aws_s3_bucket.console_ui_source_config
  ]
}
