resource "aws_ecr_repository" "daskhub_ecr_repo" {
  name                 = lower("fd-daskhub-${var.project_name}-${var.daskhub_stage}")
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "random_id" "suffix" {
  byte_length = 8
}

resource "aws_s3_bucket" "docker_image_build_source" {
  bucket        = "fd-daskhub-image-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "docker_image_build_source_ownership_controls" {
  bucket = aws_s3_bucket.docker_image_build_source.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "docker_image_build_source_public_access_block" {
  bucket = aws_s3_bucket.docker_image_build_source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "docker_image_build_source_versioning" {
  bucket = aws_s3_bucket.docker_image_build_source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "docker_build_dockerfile" {
  bucket = aws_s3_bucket.docker_image_build_source.id
  key    = "Dockerfile"
  source = "${path.module}/docker_build/daskhub/Dockerfile"
  etag   = filemd5("${path.module}/docker_build/daskhub/Dockerfile")
}

resource "aws_s3_object" "docker_build_spec" {
  bucket = aws_s3_bucket.docker_image_build_source.id
  key    = "buildspec.yml"
  source = "${path.module}/docker_build/buildspec.yml"
  etag   = filemd5("${path.module}/docker_build/buildspec.yml")
}

resource "aws_codebuild_project" "daskhub_docker_image" {
  name                   = "fd-daskhub-docker-image-${var.project_name}-${var.daskhub_stage}"
  description            = "Builds a daskhub Docker image"
  concurrent_build_limit = 1
  build_timeout          = "10"
  queued_timeout         = "30"
  service_role           = aws_iam_role.docker_image_codebuild_iam_role.arn

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
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.daskhub_ecr_repo.name
    }

    environment_variable {
      name  = "daskhub_STAGE"
      value = var.daskhub_stage
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/filmdrop/daskhub_image_build"
      stream_name = "docker-image-build-daskhub"
    }
  }

  source {
    type     = "S3"
    location = "${aws_s3_bucket.docker_image_build_source.arn}/"
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.private_subnet_ids
    security_group_ids = var.security_group_ids
  }
}

resource "null_resource" "trigger_codebuild" {
  triggers = {
    new_docker_image = filemd5("${path.module}/docker_build/daskhub/Dockerfile")
    new_build_spec   = filemd5("${path.module}/docker_build/buildspec.yml")
    new_codebuild    = aws_codebuild_project.daskhub_docker_image.id
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Triggering CodeBuild Project."
START_RESULT=$(aws codebuild start-build --project-name ${aws_codebuild_project.daskhub_docker_image.id})
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
    echo "CodeBuild ${aws_codebuild_project.daskhub_docker_image.id} succeeded"
fi

EOF

  }

  depends_on = [
    aws_s3_object.docker_build_dockerfile,
    aws_s3_object.docker_build_spec,
    aws_codebuild_project.daskhub_docker_image
  ]
}

resource "null_resource" "cleanup_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.docker_image_build_source.id
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
    aws_s3_bucket.docker_image_build_source
  ]
}
