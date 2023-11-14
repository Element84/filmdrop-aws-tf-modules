
locals {
  valid_web_acl_name = replace(replace(var.web_acl_name, "_", ""), "-", "")
}
