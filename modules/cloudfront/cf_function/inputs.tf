variable "name" {
  description = "Name of the CF function"
}

variable "runtime" {
  description = "Runtime of CF function"
  default     = "cloudfront-js-1.0"
}

variable "comment" {
  description = "Comment for the CF function"
  default     = ""
}

variable "publish" {
  description = "Value to publish or not"
  default     = true
}

variable "code_path" {
  description = "CF function code file name with path"
}