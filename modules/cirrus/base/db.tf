resource "aws_dynamodb_table" "cirrus_state_dynamodb_table" {
  name         = "${var.cirrus_prefix}-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "collections_workflow"
  range_key    = "state_updated"

  attribute {
    name = "collections_workflow"
    type = "S"
  }

  attribute {
    name = "itemids"
    type = "S"
  }

  attribute {
    name = "state_updated"
    type = "S"
  }

  attribute {
    name = "updated"
    type = "S"
  }

  global_secondary_index {
    name            = "state_updated"
    hash_key        = "collections_workflow"
    range_key       = "state_updated"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "updated"
    hash_key        = "collections_workflow"
    range_key       = "updated"
    projection_type = "ALL"
  }
}

resource "aws_timestreamwrite_database" "cirrus_state_event_timestreamwrite_database" {
  database_name = "${var.cirrus_prefix}-state-events"
}

resource "aws_timestreamwrite_table" "cirrus_state_event_timestreamwrite_table" {
  database_name = aws_timestreamwrite_database.cirrus_state_event_timestreamwrite_database.database_name
  table_name    = "${var.cirrus_prefix}-state-events-table"

  retention_properties {
    magnetic_store_retention_period_in_days = var.cirrus_timestream_magnetic_store_retention_period_in_days
    memory_store_retention_period_in_hours  = var.cirrus_timestream_memory_store_retention_period_in_hours
  }
}
