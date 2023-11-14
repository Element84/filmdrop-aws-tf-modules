variable "sns_topics_map" {
    default = {}
}

locals{
 default_sns_policy_file_path_name = "./modules/base_infra/sns/policy_files/sns_policy.json.tpl"
}