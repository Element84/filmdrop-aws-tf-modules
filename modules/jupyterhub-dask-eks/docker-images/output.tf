output "daskhub_repo" {
  value = aws_ecr_repository.daskhub_ecr_repo.repository_url
}

output "daskhub_dockerfile_hash" {
  value = filemd5("${path.module}/docker_build/daskhub/Dockerfile")
}

output "daskhub_buildspec_hash" {
  value = filemd5("${path.module}/docker_build/buildspec.yml")
}
