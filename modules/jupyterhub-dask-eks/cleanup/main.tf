resource "aws_lambda_function" "analytics_cleanup_lambda" {
  filename         = data.archive_file.cleanup_lambda_zip.output_path
  source_code_hash = data.archive_file.cleanup_lambda_zip.output_base64sha256
  function_name    = "${var.analytics_cluster_name}-cleanup"
  role             = aws_iam_role.analytics_cleanup_lambda_role.arn
  description      = "Terminates extra FilmDrop Analytics nodes that may be left running in an account overnight"
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  memory_size      = "512"
  timeout          = "300"

  environment {
    variables = {
      ANALYTICS_ASG_MIN        = var.analytics_asg_min_capacity
      ANALYTICS_CLUSTER_NAME   = var.analytics_cluster_name
      ANALYTICS_DASK_NODE_NAME = "${var.analytics_cluster_name}-dask-workers-Node"
      ANALYTICS_MAIN_NODE_NAME = "${var.analytics_cluster_name}-main-Node"
    }
  }
}

resource "aws_lambda_function" "analytics_notifications_lambda" {
  filename         = data.archive_file.notifications_lambda_zip.output_path
  source_code_hash = data.archive_file.notifications_lambda_zip.output_base64sha256
  function_name    = "${var.analytics_cluster_name}-notifications"
  role             = aws_iam_role.analytics_cleanup_lambda_role.arn
  description      = "Sends notification if FilmDrop Analytics node limit for normal usage has been exceeded"
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  memory_size      = "512"
  timeout          = "300"

  environment {
    variables = {
      ANALYTICS_NODE_LIMIT     = var.analytics_node_limit
      ANALYTICS_DASK_NODE_NAME = "${var.analytics_cluster_name}-dask-workers-Node"
      ANALYTICS_MAIN_NODE_NAME = "${var.analytics_cluster_name}-main-Node"
      SNS_TOPIC_ARN            = aws_sns_topic.analytics_notifications_sns_topic.arn
      STAGE                    = var.analytics_cleanup_stage
    }
  }
}

resource "aws_sns_topic" "analytics_notifications_sns_topic" {
  name = "${var.analytics_cluster_name}-notifications"
}

resource "aws_sns_topic" "analytics_trigger_sns_topic" {
  name = "${var.analytics_cluster_name}-triggers"
}

resource "aws_sns_topic_subscription" "analytics_trigger_sns_subscription" {
  topic_arn = aws_sns_topic.analytics_trigger_sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.analytics_notifications_lambda.arn
}

resource "aws_lambda_permission" "analytics_trigger_sns_permission" {
  action        = "lambda:*"
  function_name = aws_lambda_function.analytics_notifications_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.analytics_trigger_sns_topic.arn
}

resource "aws_cloudwatch_event_rule" "analytics_notifications_event_rule" {
  count               = length(var.analytics_notifications_schedule_expressions)
  name                = "${var.analytics_cluster_name}-notifications-${count.index}"
  schedule_expression = var.analytics_notifications_schedule_expressions[count.index]
}

resource "aws_cloudwatch_event_target" "analytics_notifications_event_target" {
  count     = length(var.analytics_notifications_schedule_expressions)
  rule      = aws_cloudwatch_event_rule.analytics_notifications_event_rule[count.index].name
  target_id = "analyticsNotifications"
  arn       = aws_lambda_function.analytics_notifications_lambda.arn
}

resource "aws_lambda_permission" "analytics_notifications_event_rule_permission" {
  count         = length(var.analytics_notifications_schedule_expressions)
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_notifications_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.analytics_notifications_event_rule[count.index].arn
}

resource "aws_cloudwatch_event_rule" "analytics_cleanup_event_rule" {
  count               = length(var.analytics_cleanup_schedule_expressions)
  name                = "${var.analytics_cluster_name}-cleanup-${count.index}"
  schedule_expression = var.analytics_cleanup_schedule_expressions[count.index]
}

resource "aws_cloudwatch_event_target" "analytics_cleanup_event_target" {
  count     = length(var.analytics_cleanup_schedule_expressions)
  rule      = aws_cloudwatch_event_rule.analytics_cleanup_event_rule[count.index].name
  target_id = "analyticsCleanup"
  arn       = aws_lambda_function.analytics_cleanup_lambda.arn
}

resource "aws_lambda_permission" "analytics_cleanup_event_rule_permission" {
  count         = length(var.analytics_cleanup_schedule_expressions)
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_cleanup_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.analytics_cleanup_event_rule[count.index].arn
}

resource "null_resource" "analytics_cleanup_lambda" {
  triggers = {
    analytics_cleanup_lambda   = aws_lambda_function.analytics_cleanup_lambda.arn
    analytics_asg_min_capacity = var.analytics_asg_min_capacity
    analytics_cluster_name     = var.analytics_cluster_name
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Running FilmDrop Analytics Cleanup Lambda."
aws lambda invoke --function-name ${aws_lambda_function.analytics_cleanup_lambda.function_name} --payload '{ }' output

EOF

  }

  depends_on = [
    aws_lambda_function.analytics_cleanup_lambda
  ]
}
