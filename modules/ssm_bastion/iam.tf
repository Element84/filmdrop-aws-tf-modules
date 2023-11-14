resource "aws_iam_role" "ssm_bastion_role" {
  name_prefix = "ssm-bastion-role-"

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

resource "aws_iam_policy" "kms_access_policy" {
  name_prefix = "ssm-bastion-access"

  policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": [
                  "ec2:AssociateAddress",
                  "ec2:DescribeAddresses"
              ],
              "Resource": [
                  "*"
              ],
              "Effect": "Allow"
          },
          {
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey"
            ],
            "Resource": "${aws_kms_key.bucket_encryption_key.arn}"
          }
      ]
  }
EOF

}

resource "aws_iam_role_policy_attachment" "bastion_ssm_kms" {
  role       = aws_iam_role.ssm_bastion_role.name
  policy_arn = aws_iam_policy.kms_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_registration_core" {
  role       = aws_iam_role.ssm_bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_registration_cloudwatch" {
  role       = aws_iam_role.ssm_bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonS3ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.ssm_bastion_role.name
}

resource "aws_iam_role_policy_attachment" "AcceleratorSSMPolicy" {
  count      = var.attach_accelerator_policy == true ? 1 : 0
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AWSAccelerator-SessionManagerUserKMS-${data.aws_region.current.name}"
  role       = aws_iam_role.ssm_bastion_role.name
}

resource "aws_iam_instance_profile" "ssm_bastion_profile" {
  name = "ssm-bastion-profile"
  role = aws_iam_role.ssm_bastion_role.name
}
