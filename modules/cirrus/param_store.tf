locals {
  pointer_prefix    = "/cirrus/deployments/"
  deployment_name   = "${var.project_name}-${var.environment}"
  deployment_prefix = "/deployment/"
}
resource "aws_ssm_parameter" "deployment_pointer" {
  name = "${local.pointer_prefix}${local.deployment_name}"
  type = "String"
  value = jsonencode({
    type  = "parameter_store"
    value = "${local.deployment_prefix}${local.deployment_name}"
    }
  )
}

resource "aws_ssm_parameter" "event_db_and_table" {
  name  = "${local.deployment_prefix}${local.deployment_name}/CIRRUS_EVENT_DB_AND_TABLE"
  type  = "String"
  value = "${module.base.cirrus_state_event_timestreamwrite_database_name}|${module.base.cirrus_state_event_timestreamwrite_table_name}"
}

resource "aws_ssm_parameter" "payload_bucket" {
  name  = "${local.deployment_prefix}${local.deployment_name}/CIRRUS_PAYLOAD_BUCKET"
  type  = "String"
  value = module.base.cirrus_payload_bucket
}

resource "aws_ssm_parameter" "publish_topic_arn" {
  name  = "${local.deployment_prefix}${local.deployment_name}/CIRRUS_PUBLISH_TOPIC_ARN"
  type  = "String"
  value = module.base.cirrus_publish_sns_topic_arn
}

resource "aws_ssm_parameter" "process_queue_url" {
  name  = "${local.deployment_prefix}${local.deployment_name}/CIRRUS_PROCESS_QUEUE_URL"
  type  = "String"
  value = module.base.cirrus_process_sqs_queue_url
}

resource "aws_ssm_parameter" "workflow_event_topic_arn" {
  name  = "${local.deployment_prefix}${local.deployment_name}/CIRRUS_WORKFLOW_EVENT_TOPIC_ARN"
  type  = "String"
  value = module.base.cirrus_workflow_event_sns_topic_arn
}

resource "aws_ssm_parameter" "log_level" {
  name  = "${local.deployment_prefix}${local.deployment_name}/CIRRUS_LOG_LEVEL"
  type  = "String"
  value = "DEBUG"
}

resource "aws_ssm_parameter" "state_db" {
  name  = "${local.deployment_prefix}${local.deployment_name}/CIRRUS_STATE_DB"
  type  = "String"
  value = module.base.cirrus_state_dynamodb_table_name
}

resource "aws_ssm_parameter" "base_workflow_arn" {
  name  = "${local.deployment_prefix}${local.deployment_name}/CIRRUS_BASE_WORKFLOW_ARN"
  type  = "String"
  value = module.workflow.state_machine_arn
}

resource "aws_ssm_parameter" "cirrus_prefix" {
  name  = "${local.deployment_prefix}${local.deployment_name}/CIRRUS_PREFIX"
  type  = "String"
  value = module.base.cirrus_prefix
}


