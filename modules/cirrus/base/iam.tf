resource "aws_iam_role" "cirrus_batch_role" {
  name_prefix = "${var.cirrus_prefix}-batch-role-"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Condition": {
        "StringEquals": {
            "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
        },
        "ArnLike": {
            "aws:SourceArn": "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }
  ]
}
EOF

}

resource "aws_iam_policy" "cirrus_batch_policy" {
  name_prefix = "${var.cirrus_prefix}-batch-policy-"

  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": [
				"s3:PutObject"
			],
			"Resource": [
				"arn:aws:s3:::${var.cirrus_data_bucket}*",
				"arn:aws:s3:::${var.cirrus_payload_bucket}*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"s3:ListBucket",
				"s3:GetObject",
				"s3:GetBucketLocation"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Action": "secretsmanager:GetSecretValue",
			"Resource": [
				"arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.cirrus_prefix}*"
			],
			"Effect": "Allow"
		},
		{
			"Action": [
				"lambda:GetFunction"
			],
			"Resource": [
				"arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.cirrus_prefix}*"
			],
			"Effect": "Allow"
		}
	]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cirrus_batch_role_policy_attachment" {
  role       = aws_iam_role.cirrus_batch_role.name
  policy_arn = aws_iam_policy.cirrus_batch_policy.arn
}

resource "aws_iam_role" "cirrus_instance_role" {
  name_prefix = "${var.cirrus_prefix}-instance-role-"

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
  name_prefix = "${var.cirrus_prefix}-instance-profile-"
  role        = aws_iam_role.cirrus_instance_role.name
}

resource "aws_iam_role" "cirrus_ec2_spot_role" {
  name_prefix = "${var.cirrus_prefix}-ec2-spot-role-"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "spotfleet.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cirrus_ec2_spot_role_policy_attachment" {
  role       = aws_iam_role.cirrus_ec2_spot_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}
