data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

resource "random_id" "suffix" {
  byte_length = 16
}
