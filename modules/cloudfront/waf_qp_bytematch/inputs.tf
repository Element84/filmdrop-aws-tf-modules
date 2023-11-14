variable "web_acl_name" {
    description = "Name of the web ACL"
}

variable "web_acl_desc" {
  description = "Web ACL description"
  default = "Web ACL with query param rule"
}

variable "wacl_default_action" {
  description = "Default action for Web ACL allow/block"
  default = "block"
}

variable "waf_rules_map" {
  description = "map of waf rules"
  type = map(any)
}

variable "wacl_cloudwatch_metrics_enabled" {
  description = "Boolean for wacl cloudwatch metrics enabled"
  default = "false"
}

variable "wacl_sampled_requests_enabled" {
  description = "Boolean for wacl sampled requests enabled"
  default = "false"
}
