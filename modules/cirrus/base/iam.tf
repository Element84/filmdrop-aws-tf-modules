resource "aws_iam_role" "cirrus_instance_role" {
  name_prefix = "${var.resource_prefix}-instance-role-"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cirrus_instance_role_policy_attachment" {
  role       = aws_iam_role.cirrus_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "cirrus_instance_profile" {
  name_prefix = "${var.resource_prefix}-instance-profile-"
  role        = aws_iam_role.cirrus_instance_role.name
}
