resource "random_id" "suffix" {
  byte_length = 8
}

resource "aws_cloudwatch_metric_alarm" "warning_titiler_invocations" {
  alarm_name          = "${var.project_name}_warning_titiler_invocations-${random_id.suffix.hex}"
  alarm_description   = "(Warning) Number of TiTiler Invocations has surpassed the Warning threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "Invocations"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.warning_titiler_invocations
  dimensions = {
    FunctionName = aws_lambda_function.titiler-mosaic-lambda.function_name
  }
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  depends_on = [
    aws_lambda_function.titiler-mosaic-lambda
  ]
}

resource "aws_cloudwatch_metric_alarm" "warning_titiler_errors" {
  alarm_name          = "${var.project_name}_warning_titiler_errors-${random_id.suffix.hex}"
  alarm_description   = "(Warning) Number of TiTiler Errors has surpassed the Warning threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.warning_titiler_errors
  dimensions = {
    FunctionName = aws_lambda_function.titiler-mosaic-lambda.function_name
  }
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  depends_on = [
    aws_lambda_function.titiler-mosaic-lambda
  ]
}

resource "aws_cloudwatch_metric_alarm" "critical_titiler_errors" {
  alarm_name          = "${var.project_name}_critical_titiler_errors-${random_id.suffix.hex}"
  alarm_description   = "(Critical) Number of TiTiler Errors has surpassed the Critical threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  treat_missing_data  = "ignore"
  statistic           = "Sum"
  threshold           = var.critical_titiler_errors
  dimensions = {
    FunctionName = aws_lambda_function.titiler-mosaic-lambda.function_name
  }
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  depends_on = [
    aws_lambda_function.titiler-mosaic-lambda
  ]
}