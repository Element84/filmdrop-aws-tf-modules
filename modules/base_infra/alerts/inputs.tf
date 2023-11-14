variable "cloudwatch_alarms_map" {
  type    = map(any)
  default = {}
}

variable "alarm_actions_list" {
  type    = list(string)
  default = []
}

variable "ok_actions_list" {
  type    = list(string)
  default = []
}

variable "insufficient_data_actions_list" {
  type    = list(string)
  default = []
}


variable "cloudwatch_event_rules_map" {
  type    = map(any)
  default = {}
}

variable "events_target_name" {
  type    = string
  default = ""
}

variable "events_target_arn" {
  type    = string
  default = ""
}
