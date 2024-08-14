resource "aws_sns_topic" "cirrus_publish_sns_topic" {
  name = "${var.cirrus_prefix}-publish"
}

resource "aws_sns_topic" "cirrus_workflow_event_sns_topic" {
  name = "${var.cirrus_prefix}-workflow-event"
}
