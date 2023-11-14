resource "aws_instance" "ssm_bastion" {
  ami                  = data.aws_ami.latest_amazon_linux.id
  iam_instance_profile = aws_iam_instance_profile.ssm_bastion_profile.name
  instance_type        = var.instance_type
  user_data            = data.template_file.user_data.rendered
  key_name             = var.key_name
  security_groups      = [aws_security_group.ssm_security_group.id]
  subnet_id            = var.subnet_ids[0]

  tags = {
    Name = "FilmDrop SSM JumpBox"
  }
}

resource "aws_ebs_volume" "swap" {
  size              = var.swap_volume_size
  availability_zone = aws_instance.ssm_bastion.availability_zone
  type              = "gp2"

  tags = {
    Name = "FilmDrop SSM JumpBox - swap volume"
  }
}

resource "aws_volume_attachment" "swap_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.swap.id
  instance_id = aws_instance.ssm_bastion.id

  force_detach = true
}

resource "aws_security_group" "ssm_security_group" {
  name        = "ssm-sg-${random_id.suffix.hex}"
  description = "SSM JumpBox Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_range]
    description = "Inbound VPC Access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound Access"
  }

  lifecycle {
      ignore_changes = [ingress, egress]
  }
}
