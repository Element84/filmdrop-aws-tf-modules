resource "aws_sqs_queue" "feeder_queue" {
  name = local.name_main
}
