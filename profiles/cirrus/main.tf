module "cirrus" {
  source = "../../modules/cirrus"

  project_name                                              = var.project_name
  environment                                               = var.environment
  cirrus_process_sqs_timeout                                = var.cirrus_inputs.process.sqs_timeout
  cirrus_process_sqs_max_receive_count                      = var.cirrus_inputs.process.sqs_max_receive_count
  cirrus_timestream_magnetic_store_retention_period_in_days = var.cirrus_inputs.state.timestream_magnetic_store_retention_period_in_days
  cirrus_timestream_memory_store_retention_period_in_hours  = var.cirrus_inputs.state.timestream_memory_store_retention_period_in_hours
  cirrus_data_bucket                                        = var.cirrus_inputs.data_bucket
  cirrus_payload_bucket                                     = var.cirrus_inputs.payload_bucket
}
