# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "workflow_events" {
  name              = "${var.resource_prefix}-workflow-event-metrics"
  retention_in_days = 14
}

# Metric Filter 1: all_workflows_by_event
resource "aws_cloudwatch_log_metric_filter" "all_workflows_by_event" {
  name           = "all_workflows_by_event"
  log_group_name = aws_cloudwatch_log_group.workflow_events.name
  pattern        = "{$.event = \"*\"}"

  metric_transformation {
    name      = "all_workflows_by_event"
    namespace = "${var.resource_prefix}-workflow"
    value     = "1"
    dimensions = {
      event = "$.event"
    }
  }
}

# Metric Filter 2: a_workflow_by_event
resource "aws_cloudwatch_log_metric_filter" "a_workflow_by_event" {
  name           = "a_workflow_by_event"
  log_group_name = aws_cloudwatch_log_group.workflow_events.name
  pattern        = "{($.event = \"*\") && ($.workflow = \"*\")}"

  metric_transformation {
    name      = "a_workflow_by_event"
    namespace = "${var.resource_prefix}-workflow"
    value     = "1"
    dimensions = {
      event    = "$.event"
      workflow = "$.workflow"
    }
  }
}

data "aws_iam_policy_document" "cirrus_workflow_metrics_write_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      aws_cloudwatch_log_group.workflow_events.arn
    ]
  }
}

data "aws_iam_policy_document" "cirrus_workflow_metrics_read_policy_doc" {
  statement {
    actions = [
      "cloudwatch:GetMetricData",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["${var.resource_prefix}-workflow"]
    }
  }
}

resource "aws_iam_policy" "cirrus_workflow_metrics_write_policy" {
  name   = "${var.resource_prefix}-workflow-metrics-write-policy"
  policy = data.aws_iam_policy_document.cirrus_workflow_metrics_write_policy_doc.json
}

resource "aws_iam_policy" "cirrus_workflow_metrics_read_policy" {
  name   = "${var.resource_prefix}-workflow-metrics-read-policy"
  policy = data.aws_iam_policy_document.cirrus_workflow_metrics_read_policy_doc.json
}
