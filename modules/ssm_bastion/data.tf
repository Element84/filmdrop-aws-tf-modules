data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

resource "random_id" "suffix" {
  byte_length = 16
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  owners = ["amazon", data.aws_caller_identity.current.id]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    PublicKeysBucket = aws_s3_bucket.filmdrop_public_keys_bucket.id
    AWSRegion        = data.aws_region.current.name
  }
}
