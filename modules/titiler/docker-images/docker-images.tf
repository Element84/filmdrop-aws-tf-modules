resource "aws_ecr_repository" "titiler_ecr_repo" {
  name                 = "${var.prefix}titiler"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource random_id suffix {
  byte_length = 8
}

resource "aws_s3_bucket" "docker_image_build_source" {
  bucket = "titiler-image-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_acl" "docker_image_build_source_bucket_acl" {
  bucket = aws_s3_bucket.docker_image_build_source.id
  acl    = "private"
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
  source = "${path.module}/docker_build/titiler/Dockerfile"
  etag   = filemd5("${path.module}/docker_build/titiler/Dockerfile")
}

resource "aws_s3_object" "docker_build_handler" {
  bucket = aws_s3_bucket.docker_image_build_source.id
  key    = "handler.py"
  source = "${path.module}/docker_build/titiler/handler.py"
  etag   = filemd5("${path.module}/docker_build/titiler/handler.py")
}

resource "aws_s3_object" "docker_build_spec" {
  bucket = aws_s3_bucket.docker_image_build_source.id
  key    = "buildspec.yml"
  source = "${path.module}/docker_build/buildspec.yml"
  etag   = filemd5("${path.module}/docker_build/buildspec.yml")
}

resource "aws_codebuild_project" "titiler_docker_image" {
  name           = "titiler-docker-image"
  description    = "creates a titiler docker image"
  build_timeout  = "10"
  queued_timeout = "30"
  service_role   = aws_iam_role.docker_image_codebuild_iam_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:1.0"
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
      value = aws_ecr_repository.titiler_ecr_repo.name
    }

    environment_variable {
      name  = "TITILER_STAGE"
      value = var.titiler_stage
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/filmdrop/titiler_image_build"
      stream_name = "docker-image-build-titiler"
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
    new_docker_image  = filemd5("${path.module}/docker_build/titiler/Dockerfile")
    new_build_spec    = filemd5("${path.module}/docker_build/buildspec.yml")
    new_handler       = filemd5("${path.module}/docker_build/titiler/handler.py")
    new_codebuild     = aws_codebuild_project.titiler_docker_image.id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Triggering CodeBuild Project."
aws codebuild start-build --project-name ${aws_codebuild_project.titiler_docker_image.id}
EOF

  }

  depends_on = [
    aws_s3_object.docker_build_dockerfile,
    aws_s3_object.docker_build_spec,
    aws_s3_object.docker_build_handler,
    aws_codebuild_project.titiler_docker_image
  ]
}
