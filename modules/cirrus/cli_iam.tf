locals {
  create_cli_role = var.cirrus_cli_iam_role_trust_principal != null

}


resource "aws_iam_role" "cirrus_instance_cli_management_role" {
  count       = local.create_cli_role ? 1 : 0
  name_prefix = "${local.cirrus_prefix}-instance-cli-management-role-"


  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${local.create_cli_role}
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "cirrus_instance_cli_management_policy" {
  name_prefix = "${local.cirrus_prefix}-instance-cli-management-policy-"
  policy      = <<EOF
  { # what S3 services does the CLI use?
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "${module.base.cirrus_payload_bucket}",
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:BatchGetItem",
      ],
      "Resource": [
        "${module.base.cirrus_state_dynamodb_table_arn}",
        "${module.base.cirrus_state_dynamodb_table_arn}/index.*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${module.base.cirrus_process_sqs_queue_arn}"
    },
EOF
}

resource "aws_iam_role_policy_attachment" "cirrus_instance_cli_management_role_policy_attachment" {
  role       = aws_iam_role.cirrus_instance_cli_management_role[1].name
  policy_arn = aws_iam_role.cirrus_instance_cli_management_role[1].arn
}