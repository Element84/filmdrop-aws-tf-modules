variable "cloudwatch_alarms_map" {
    default = {}
}

variable "alarm_actions_list" {
    default = []
}

variable "ok_actions_list" {
    default = []
}

variable "insufficient_data_actions_list" {
    default = []
}


variable cloudwatch_event_rules_map {
    default = {}
}

variable events_target_name {
    default = ""
}

variable events_target_arn {
    default = ""
}
