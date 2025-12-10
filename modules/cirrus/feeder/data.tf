locals {
  name_main = lower("${var.resource_prefix}-feeder-${var.feeder_config.name}")
}
