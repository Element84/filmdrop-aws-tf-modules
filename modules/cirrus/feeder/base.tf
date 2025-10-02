locals {
  sqs_name = "${var.resource_prefix}-${var.feeder_config.name}"
}

resource "aws_sqs_queue" "feeder_queue" {
  name = local.sqs_name
}
