variable "sns_topics_subscriptions_map" {
  type    = map(any)
  default = {}
}

variable "sns_topic_arn" {
  type = string
}