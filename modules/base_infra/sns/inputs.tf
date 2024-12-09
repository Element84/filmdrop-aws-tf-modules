variable "sns_topics_map" {
  type    = map(any)
  default = {}
}

locals {
  default_sns_policy_file_path_name = "${path.module}/policy_files/sns_policy.json.tpl"
}