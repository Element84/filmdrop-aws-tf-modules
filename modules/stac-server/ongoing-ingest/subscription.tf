resource "aws_sns_topic_subscription" "ongoing_ingest_sqs_subscription" {
  topic_arn = var.source_sns_arn
  protocol  = "sqs"
  endpoint  = var.ingest_sqs_arn

  filter_policy = jsonencode({
    "collection" : split(",", var.destination_collections_list),
    "bbox.ll_lon" : [{ "numeric" : [">=", var.destination_collections_min_long] }],
    "bbox.ll_lat" : [{ "numeric" : [">=", var.destination_collections_min_lat] }],
    "bbox.ur_lon" : [{ "numeric" : ["<=", var.destination_collections_max_long] }],
    "bbox.ur_lat" : [{ "numeric" : ["<=", var.destination_collections_max_lat] }]
  })
}
