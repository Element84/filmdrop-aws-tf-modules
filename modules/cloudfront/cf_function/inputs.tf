variable "name" {
  description = "Name of the CF function"
  type        = string
}

variable "runtime" {
  description = "Runtime of CF function"
  type        = string
  default     = "cloudfront-js-1.0"
}

variable "comment" {
  description = "Comment for the CF function"
  type        = string
  default     = ""
}

variable "publish" {
  description = "Value to publish or not"
  type        = string
  default     = true
}

variable "code_path" {
  description = "CF function code file name with path"
  type        = string
}