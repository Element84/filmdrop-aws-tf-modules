variable "environment" {
  description = "Project environment"
  type        = string
  validation {
    condition     = length(var.environment) <= 7
    error_message = "The environment value must be 7 or fewer characters."
  }
}

# TODO - CVG - resource naming - temporarily increasing project name length
variable "project_name" {
  description = "Project Name"
  type        = string
  validation {
    condition     = length(var.project_name) <= 10
    error_message = "The project_name value must be a 10 or fewer characters."
  }
}

variable "cirrus_lambda_zip_filepath" {
  description = <<-DESCRIPTION
  (Optional) Filepath to a Cirrus Lambda Dist ZIP relative to the root module
  of this Terraform deployment. Used to override the ZIP that's included with
  this module; only set if you're confident the replacement ZIP is compatible
  with this module. If omitted, the default ZIP is used.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "cirrus_process_sqs_timeout" {
  description = "Cirrus Process SQS Visibility Timeout"
  type        = number
  default     = 180
}

variable "cirrus_process_sqs_max_receive_count" {
  description = "Cirrus Process SQS Max Receive Count"
  type        = number
  default     = 5
}

variable "cirrus_timestream_magnetic_store_retention_period_in_days" {
  description = "Cirrus Timestream duration for which data must be stored in the magnetic store"
  type        = number
  default     = 93
}

variable "cirrus_timestream_memory_store_retention_period_in_hours" {
  description = "Cirrus Timestream duration for which data must be stored in the memory store"
  type        = number
  default     = 24
}

variable "cirrus_data_bucket" {
  description = "Cirrus data bucket"
  type        = string
}

variable "cirrus_payload_bucket" {
  description = "Cirrus payload bucket"
  type        = string
}

variable "cirrus_log_level" {
  description = "Cirrus log level (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"
}

variable "cirrus_api_rest_type" {
  description = "Cirrus API Gateway type"
  type        = string
  default     = "EDGE"
}

variable "cirrus_api_lambda_timeout" {
  description = "Cirrus API lambda timeout (sec)"
  type        = number
  default     = 10
}

variable "cirrus_api_lambda_memory" {
  description = "Cirrus API lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_process_lambda_timeout" {
  description = "Cirrus process lambda timeout (sec)"
  type        = number
  default     = 10
}

variable "cirrus_process_lambda_memory" {
  description = "Cirrus process lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_process_lambda_reserved_concurrency" {
  description = "Cirrus process reserved concurrency"
  type        = number
  default     = 16
}

variable "cirrus_update_state_lambda_timeout" {
  description = "Cirrus update-state lambda timeout (sec)"
  type        = number
  default     = 15
}

variable "cirrus_update_state_lambda_memory" {
  description = "Cirrus update-state lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_pre_batch_lambda_timeout" {
  description = "Cirrus pre-batch lambda timeout (sec)"
  type        = number
  default     = 15
}

variable "cirrus_pre_batch_lambda_memory" {
  description = "Cirrus pre-batch lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_post_batch_lambda_timeout" {
  description = "Cirrus post-batch lambda timeout (sec)"
  type        = number
  default     = 15
}

variable "cirrus_post_batch_lambda_memory" {
  description = "Cirrus post-batch lambda memory (MB)"
  type        = number
  default     = 128
}

variable "vpc_id" {
  description = "FilmDrop VPC ID"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
}

variable "warning_sns_topic_arn" {
  description = "String with FilmDrop Warning SNS topic ARN"
  type        = string
}

variable "critical_sns_topic_arn" {
  description = "String with FilmDrop Critical SNS topic ARN"
  type        = string
}

variable "deploy_alarms" {
  type        = bool
  default     = true
  description = "Deploy Cirrus Alarms stack"
}

variable "custom_cloudwatch_warning_alarms_map" {
  description = "Map with custom CloudWatch Warning Alarms"
  type        = map(any)
  default     = {}
}

variable "custom_cloudwatch_critical_alarms_map" {
  description = "Map with custom CloudWatch Critical Alarms"
  type        = map(any)
  default     = {}
}

variable "cirrus_task_batch_compute_definitions_dir" {
  description = <<-DESCRIPTION
  (Optional) Filepath to a directory containing task batch compute definition
  subdirectories. Path is relative to this Terraform deployment's root module.
  The directory's expected subdirectory structure is:

    example-compute-1/
      definition.yaml
      README.md (optional)
    example-compute-2/
      definition.yaml
      README.md (optional)
    ... more task-batch-compute subdirs ...

  Where each definition.yaml is a YAML representation of the task-batch-compute
  module's "batch_compute_config" HCL object. See that module's inputs.tf for
  valid object attributes.

  If null, no task-batch-compute resources will be created.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "cirrus_task_definitions_dir" {
  description = <<-DESCRIPTION
  (Optional) Filepath to directory containing task definition subdirectories.
  Path is relative to this Terraform deployment's root module. The directory's
  expected subdirectory structure is:

    example-task-1/
      definition.yaml
      README.md (optional)
    example-task-2/
      definition.yaml
      README.md (optional)
    ... more task subdirs ...

  Where each definition.yaml is a YAML representation of the task module's
  "task_config" HCL object. See that module's inputs.tf for valid object
  attributes.

  If null, no task resources will be created.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "cirrus_task_definitions_variables" {
  description = <<-DESCRIPTION
  (Optional) Map of maps to strings used when templating task YAML definitions
  prior to their conversion to HCL. Intended for abstracting environment-
  specific values away from the task definition. The expected (but not
  explicitly required) structure of this map is:

    {
      example-task-1 = {
        image_tag = "v1.0"
      }
      example-task-2 = {
        image_tag = "v1.3"
        source_data_bucket = "dev-source-data-bucket-name"
      }
      ... other task maps ...
    }

  Your task YAML definitions would leverage this templating by using an
  interpolation sequence $\{...} like so (remove the "\"):

    name: example-task-2
    common_role_statements:
      - sid: ReadSomeBucketThatChangesForEachEnvironment
        effect: Allow
        actions:
          - s3:ListBucket
          - s3:GetObject
          - s3:GetBucketLocation
        resources:
          - arn:aws:s3:::$\{example-task-2.source_data_bucket}   # remove the \
          - arn:aws:s3:::$\{example-task-2.source_data_bucket}/* # remove the \
    lambda:
      ecr_image_uri: <full ECR image URI>:$\{example-task-2.image_tag} # remove the \
      ... any other config ...
  DESCRIPTION
  type        = map(map(string))
  nullable    = false
  default     = {}
}

variable "cirrus_workflow_definitions_dir" {
  description = <<-DESCRIPTION
  (Optional) Filepath to directory containing workflow definition
  subdirectories. Path is relative to this Terraform deployment's root module.
  The directory's expected subdirectory structure is:

    example-workflow-1/
      definition.yaml
      state-machine.json
      README.md (optional)
    example-workflow-2/
      definition.yaml
      state-machine.json
      README.md (optional)
    ... more workflow subdirs ...

  Where each definition.yaml is a YAML representation of the workflow module's
  "workflow_config" HCL object. See that module's inputs.tf for valid object
  attributes.

  If null, no workflow resources will be created.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}
