variable "resource_prefix" {
  description = "String prefix to be used in every named resource."
  type        = string
  nullable    = false

  # We limit the prefix length to 22 characters as that's just under the
  # maximum possible length before we run into issues with 'name_prefix' limits
  # on certain resources like IAM roles.
  # We limit the character set to lowered alphanumerics and hyphens for
  # consistency across FilmDrop modules. A leading hyphen is not allowed as that
  # is generally not a valid AWS resource name. A trailing hyphen is not allowed
  # as this module will add one where needed.
  validation {
    condition     = can(regex("^[0-9a-z][0-9a-z-]{0,20}[0-9a-z]$", var.resource_prefix))
    error_message = <<-ERROR
    The resource prefix must be 2-22 characters from [a-z0-9-] without a leading
    or trailing hyphen.
    ERROR
  }
}

variable "project_name" {
  description = "Project name."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Project environment name."
  type        = string
  nullable    = false
}

variable "vpc_id" {
  description = "VPC in which all cirrus resources will be deployed."
  type        = string
  nullable    = false
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the target VPC that cirrus resources should be connected to."
  type        = list(string)
  nullable    = false
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the target VPC that cirrus resources should use."
  type        = list(string)
  nullable    = false
}

variable "cirrus_lambda_version" {
  description = <<-DESCRIPTION
  (Optional) Version of Cirrus lambda to deploy. Please ensure the Cirrus version you set is compatible with this module.

  If `null`, defaults to the Cirrus version associated with this FilmDrop release.

  See [cirrus-geo releases](https://github.com/cirrus-geo/cirrus-geo/releases) for more information.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "cirrus_lambda_zip_filepath" {
  description = <<-DESCRIPTION
  (Optional) Filepath to a Cirrus Lambda Dist ZIP relative to the root module of
  this Terraform deployment. If provided, will not download from GitHub Releases
  the version of Cirrus as specified in `cirrus_lambda_version`.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "cirrus_data_bucket" {
  description = <<-DESCRIPTION
  (Optional) S3 bucket for storing cirrus outputs. If provided, the bucket is presumed to have already been created outside of this module and that you have the necessary permissions in place to allow access for resources created by this module.

  If `null` or `""`, the bucket will be created and tracked by this module instead.
  DESCRIPTION
  type        = string
  nullable    = false
  default     = ""
}

variable "cirrus_payload_bucket" {
  description = <<-DESCRIPTION
  (Optional) S3 bucket for storing cirrus payloads. If provided, the bucket is presumed to have already been created outside of this module and that you have the necessary permissions in place to allow access for resources created by this module.

  If `null` or `""`, the bucket will be created and tracked by this module instead.
  DESCRIPTION
  type        = string
  nullable    = false
  default     = ""
}

variable "cirrus_api_rest_type" {
  description = <<-DESCRIPTION
  (Optional) Cirrus API Gateway type.

  Must be one of: `EDGE`, `REGIONAL`, or `PRIVATE`.
  DESCRIPTION
  type        = string
  nullable    = false
  default     = "EDGE"

  validation {
    condition     = contains(["EDGE", "REGIONAL", "PRIVATE"], var.cirrus_api_rest_type)
    error_message = "Cirrus API rest type must be one of: EDGE, REGIONAL, or PRIVATE."
  }
}

variable "cirrus_private_api_additional_security_group_ids" {
  description = <<-DESCRIPTION
  (Optional) List of security group IDs that'll be applied to the VPC interface endpoints of a PRIVATE-type cirrus API Gateway.

  These security groups are in addition to the security groups that allow traffic from the `var.vpc_subnet_ids` CIDR ranges.

  Only applicable when `var.cirrus_api_rest_type` is `PRIVATE`.
  DESCRIPTION
  type        = list(string)
  nullable    = true
  default     = null
}

variable "cirrus_log_level" {
  description = <<-DESCRIPTION
  (Optional) Cirrus log level. Passed to each of the cirrus lambda functions as the `CIRRUS_LOG_LEVEL` environment variable.

  Must be one of: `DEBUG`, `INFO`, `WARNING`, or `ERROR`.
  DESCRIPTION
  type        = string
  nullable    = false
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.cirrus_log_level)
    error_message = "Cirrus log level must be one of: DEBUG, INFO, WARNING, or ERROR."
  }
}

variable "cirrus_api_lambda_timeout" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `api` lambda timeout (seconds).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 10
}

variable "cirrus_api_lambda_memory" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `api` lambda memory (MB).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 128
}

variable "cirrus_process_lambda_timeout" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `process` lambda timeout (seconds).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 10
}

variable "cirrus_process_lambda_memory" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `process` lambda memory (MB).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 128
}

variable "cirrus_process_lambda_reserved_concurrency" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `process` lambda reserved concurrent executions. See [lambda concurrency AWS documentation](https://docs.aws.amazon.com/lambda/latest/dg/lambda-concurrency.html).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 16
}

variable "cirrus_process_sqs_timeout" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `process` SQS queue visibility timeout (seconds). This should exceed `var.cirrus_process_lambda_timeout` to ensure messages are not re-enqueued prior to `process` lambda completion.
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 180
}

variable "cirrus_process_sqs_max_receive_count" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `process` SQS queue max receive count. Used in the redrive policy to set a message's maximum attempts before being moved to the `process`'s dead-letter queue.
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 5
}

variable "cirrus_update_state_lambda_timeout" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `update-state` lambda timeout (seconds).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 15
}

variable "cirrus_update_state_lambda_memory" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `update-state` lambda memory (MB).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 128
}

variable "cirrus_pre_batch_lambda_timeout" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `pre-batch` lambda timeout (seconds).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 15
}

variable "cirrus_pre_batch_lambda_memory" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `pre-batch` lambda memory (MB).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 128
}

variable "cirrus_post_batch_lambda_timeout" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `post-batch` lambda timeout (seconds).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 15
}

variable "cirrus_post_batch_lambda_memory" {
  description = <<-DESCRIPTION
  (Optional) Cirrus `post-batch` lambda memory (MB).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 128
}

variable "cirrus_timestream_magnetic_store_retention_period_in_days" {
  description = <<-DESCRIPTION
  (Optional) Duration for which cirrus state events must be stored in the Timestream database table's magnetic store (days).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 93
}

variable "cirrus_timestream_memory_store_retention_period_in_hours" {
  description = <<-DESCRIPTION
  (Optional) Duration for which cirrus state events must be stored in the Timestream database table's memory store (hours).
  DESCRIPTION
  type        = number
  nullable    = false
  default     = 24
}

variable "deploy_alarms" {
  description = <<-DESCRIPTION
  (Optional) Whether CloudWatch alarms should be deployed.
  DESCRIPTION
  type        = bool
  nullable    = false
  default     = true
}

variable "warning_sns_topic_arn" {
  description = <<-DESCRIPTION
  (Optional) SNS topic to be used by all cirrus `warning` alarms.

  Must be set if `var.deploy_alarms` is `true`. Has no effect if `var.deploy_alarms` is `false`.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "critical_sns_topic_arn" {
  description = <<-DESCRIPTION
  (Optional) SNS topic to be used by all cirrus `critical` alarms.

  Must be set if `var.deploy_alarms` is `true`. Has no effect if `var.deploy_alarms` is `false`.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "cirrus_cli_iam_role_trust_principal" {
  description = <<-DESCRIPTION
  (Optional) List of IAM principal ARNs that can assume the cirrus CLI IAM management role.

  If `null`, the role will not be created.
  DESCRIPTION
  type        = list(string)
  nullable    = true
  default     = null
}

variable "custom_cloudwatch_warning_alarms_map" {
  description = <<-DESCRIPTION
  (Optional) Map of custom CloudWatch `warning` alarms to be created. See the [custom_warning_alarms](#modules) module.
  DESCRIPTION
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "custom_cloudwatch_critical_alarms_map" {
  description = <<-DESCRIPTION
  (Optional) Map of custom CloudWatch `critical` alarms to be created. See the [custom_critical_alarms](#modules) module.
  DESCRIPTION
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "cirrus_task_batch_compute_definitions_dir" {
  description = <<-DESCRIPTION
  (Optional) Filepath to a directory containing task batch compute definition subdirectories. Path is relative to this Terraform deployment's root module.

  The specified directory's expected structure is:
  ```
  your-task-batch-compute-dir/
    example-compute-1/
      definition.yaml
      README.md (optional)
    example-compute-2/
      definition.yaml
      README.md (optional)

    ... more task-batch-compute subdirs ...
  ```

  Where each `definition.yaml` is a YAML representation of the `task-batch-compute` module's `batch_compute_config` input HCL variable. See that module's [inputs](./task-batch-compute/README.md#input_batch_compute_config) for valid `batch_compute_config` object attributes.

  This module will glob for all `definition.yaml` files that are *exactly* one subdirectory deep in the specified directory. The enclosing subdirectory's name should match the task batch compute `name`.

  If `null`, no task batch compute resources will be created.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "cirrus_task_batch_compute_definitions_variables" {
  description = <<-DESCRIPTION
  (Optional) Map of maps to strings used when templating task batch compute YAML definitions prior to their conversion to HCL. Intended for abstracting any environment-specific values away from the task batch compute definition. One such example would be restricting the maximum `vCPU` size of a batch compute environment in a `dev` environment.

  If you do not require any environment-specific values, you do not need to use this.

  The suggested (but not required) structure of this map is to group template variables by their task batch compute `name`:
  ```
  {
    example-compute-1 = {
      max_vcpus      = 10
      instance_types = ["t2.micro"]
    }
    example-compute-2 = {
      max_vcpus = 40
    }

    ... more task-batch-compute maps ...
  }
  ```

  Your task batch compute YAML definitions would leverage this templating by using an attribute lookup in an interpolation sequence (`$${...}`) like so:
  ```
  name: example-compute-1
  batch_compute_environment:
    compute_resources:
      type: EC2
      max_vcpus: \$${example-compute-1.max_vcpus}
      instance_types: \$${example-compute-1.instance_types}

  ... any other config ...
  ```

  Each interpolation sequence's lookup value must have an associated entry in this map. If not, Terraform will raise a runtime error.

  Since the Cirrus data and payload buckets will always be different for each environment, there are two predefined variables `CIRRUS_DATA_BUCKET` and `CIRRUS_PAYLOAD_BUCKET` that can be used to automatically reference these bucket names in your task batch compute definition YAML. You don't need to add entries to this variable for these.

  If `null` or `{}`, templating will technically still occur but nothing will be interpolated (provided your definition is also absent of interpolation sequences).
  DESCRIPTION
  type        = map(map(string))
  nullable    = false
  default     = {}
}

variable "cirrus_task_batch_compute_definitions_variables_ssm" {
  description = <<-DESCRIPTION
  (Optional) Map of maps to SSM parameter paths used when templating task batch compute YAML definitions prior to their conversion to HCL. This variable works identically to `cirrus_task_batch_compute_definitions_variables` but sources values from AWS Systems Manager Parameter Store instead of static configuration.

  Works identically to `cirrus_task_definitions_variables_ssm` but applies to task batch compute YAML definitions instead of task definitions. See that variable's documentation for detailed usage examples and best practices.

  Example structure:
  ```
  {
    my-compute-env = {
      instance_type = "/cirrus/task-batch-compute/my-compute-env/preferred-instance-type"
      max_vcpus     = "/cirrus/task-batch-compute/my-compute-env/max-vcpus-limit"
    }
  }
  ```
  DESCRIPTION
  type        = map(map(string))
  nullable    = false
  default     = {}
}

variable "cirrus_task_definitions_dir" {
  description = <<-DESCRIPTION
  (Optional) Filepath to directory containing task definition subdirectories. Path is relative to this Terraform deployment's root module.

  The specified directory's expected structure is:
  ```
  example-task-1/
    definition.yaml
    README.md (optional)
  example-task-2/
    definition.yaml
    README.md (optional)

  ... more task subdirs ...
  ```

  Where each `definition.yaml` is a YAML representation of the `task` module's `task_config` input HCL variable. See that module's [inputs](./task/README.md#input_task_config) for valid `task_config` object attributes.

  If `null`, no task resources will be created.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "cirrus_task_definitions_variables" {
  description = <<-DESCRIPTION
  (Optional) Map of maps to strings used when templating task YAML definitions prior to their conversion to HCL. Intended for abstracting environment-specific values away from the task definition. One such example of this would be targeting different ECR image tags in a `dev` and `prod` environment.

  The suggested (but not required) structure of this map is to group template variables by their task name:
  ```
  {
    example-task-1 = {
      image_tag = "v1.0"
    }
    example-task-2 = {
      image_tag   = "v1.3"
      data_bucket = "dev-bucket-name"
    }

    ... more task maps ...
  }
  ```

  Your task YAML definitions would leverage this templating by using an attribute lookup in an interpolation sequence (`$${...}`) like so:
  ```
  name: example-task-2
  common_role_statements:
    - sid: ReadSomeBucketThatChangesForEachEnvironment
      effect: Allow
      actions:
        - s3:ListBucket
        - s3:GetObject
        - s3:GetBucketLocation
      resources:
        - arn:aws:s3:::\$${example-task-2.data_bucket}
        - arn:aws:s3:::\$${example-task-2.data_bucket}/*
  lambda:
    ecr_image_uri: your-ECR-URI:\$${example-task-2.image_tag}

  ... any other config ...
  ```

  Each interpolation sequence's lookup value must have an associated entry in this map. If not, Terraform will raise a runtime error.

  Since the Cirrus data and payload buckets will always be different for each environment, there are two predefined variables `CIRRUS_DATA_BUCKET` and `CIRRUS_PAYLOAD_BUCKET` that can be used to automatically reference these bucket names in your task definition YAML. You don't need to add entries to this variable for these.

  If `null` or `{}`, templating will technically still occur but nothing will be interpolated (provided your definition is also absent of interpolation sequences).
  DESCRIPTION
  type        = map(map(string))
  nullable    = false
  default     = {}
}

variable "cirrus_task_definitions_variables_ssm" {
  description = <<-DESCRIPTION
  (Optional) Map of maps to SSM parameter paths used when templating task YAML definitions prior to their conversion to HCL. This variable works identically to `cirrus_task_definitions_variables` but sources values from AWS Systems Manager Parameter Store instead of static configuration.

  **Important**: the targeted SSM parameter must be a simple `String` type. Do **not** use this for passing sensitive information - that is not the intended purpose of this. Values will be stored in plaintext in the state file and visible in Terraform output.

  This is particularly useful for values that change frequently or are managed by CI/CD pipelines, such as container image tags that are updated by application build processes. However, you should prefer static configuration over SSM parameters, if possible, for simplicity.

  The parameter path is arbitrary. It just needs to exist in the same account as this deployment.

  The suggested (but not required) structure of this map is to group SSM parameter mappings by their task name:
  ```
  {
    example-task-1 = {
      image_tag = "/cirrus/tasks/example-task-1/latest-image-tag"
    }
    example-task-2 = {
      image_tag = "/cirrus/tasks/example-task-2/latest-image-tag"
    }

    ... more task maps ...
  }
  ```

  Your task YAML definitions would leverage this templating using the same attribute lookup syntax as static variables:
  ```
  name: example-task-2
  lambda:
    ecr_image_uri: your-ECR-URI:\$${example-task-2.image_tag}
  batch:
    ...

  ... any other config ...
  ```

  SSM parameter values are resolved at Terraform plan time, so the current parameter values will be visible in the plan output. If both `cirrus_task_definitions_variables` and this variable contain the same task/key combination, the SSM value takes precedence. Avoid using duplicate static and SSM variable keys, though, for better readability.

  The SSM parameters must exist before running Terraform, or the plan/apply will fail. Consider bootstrapping required parameters as part of your application deployment process.

  These parameters *could* be managed elsewhere within the same Terraform deployment that manages this `cirrus` module; however, you will need to do a targeted first-time deploy of those resources before this module will work with them.

  If `null` or `{}`, no SSM parameters will be queried and templating will rely solely on static variables.
  DESCRIPTION
  type        = map(map(string))
  nullable    = false
  default     = {}
}

variable "cirrus_workflow_definitions_dir" {
  description = <<-DESCRIPTION
  (Optional) Filepath to directory containing workflow definition subdirectories. Path is relative to this Terraform deployment's root module.

  The directory's expected subdirectory structure is:
  ```
  example-workflow-1/
    definition.yaml
    state-machine.json
    README.md (optional)
  example-workflow-2/
    definition.yaml
    state-machine.json
    README.md (optional)

  ... more workflow subdirs ...
  ```

  Where each `definition.yaml` is a YAML representation of the `workflow` module's `workflow_config` input HCL variable. See that module's [inputs](./workflow/README.md#input_workflow_config) for valid `workflow_config` object attributes and also what a `state-machine.json` should look like.

  If `null`, no workflow resources will be created.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "cirrus_workflow_definitions_variables" {
  description = <<-DESCRIPTION
  (Optional) Map of maps to strings used when templating workflow YAML definitions prior to their conversion to HCL and state machine JSONs prior to state machine creation. Intended for abstracting environment-specific values away from the workflow definition and state machine JSON.

  This is only needed if your workflow's state machine will be using AWS services/resources that are unrelated to the cirrus tasks created by this module. One such example would be a workflow that leverages the callback task functionality provided by an `arn:aws:states:::sqs:sendMessage.waitForTaskToken` state machine resource.

  If your state machine does not invoke any non-cirrus task resources, you do not need to use this.

  The suggested (but not required) structure of this map is to group template variables by their workflow name:
  ```
  {
    example-workflow-1 = {
      callback_queue_arn = "dev-queue-arn"
      callback_queue_url = "https://..."
    }
    example-workflow-2 = {
      non_task_resource_arn = "dev-resource-arn"
    }

    ... more workflow maps ...
  }
  ```

  Your workflow YAML definitions would leverage this templating by using an attribute lookup in an interpolation sequence (`$${...}`) like so:
  ```
  name: example-workflow-1
  common_role_statements:
    - sid: AllowSendToCallbackQueue
      effect: Allow
      actions:
        - sqs:SendMessage
      resources:
        - arn:aws:s3:::\$${example-workflow-1.callback_queue_arn}

  ... any other config ...
  ```

  And a `State` within your workflow state machine JSON would look something like this:
  ```
  {
    "Type": "Task",
    "Resource": "arn:aws:states:::sqs:sendMessage.waitForTaskToken",
    "Parameters": {
        "QueueUrl": "\$${example-workflow-1.callback_queue_url}",
        "MessageBody": {
            "Message": "Hello from Step Functions!",
            "TaskToken.$": "$$.Task.Token"
        }
    },
    "Next": "SOME_NEXT_STATE"
  }
  ```

  Each interpolation sequence's lookup value must have an associated entry in this map. If not, Terraform will raise a runtime error.

  Since the Cirrus data and payload buckets will always be different for each environment, there are two predefined variables `CIRRUS_DATA_BUCKET` and `CIRRUS_PAYLOAD_BUCKET` that can be used to automatically reference these bucket names in your workflow definition YAML and state machine JSON. You don't need to add entries to this variable for these.

  If `null` or `{}`, templating will technically still occur but nothing will be interpolated (provided your definition is also absent of interpolation sequences).
  DESCRIPTION
  type        = map(map(string))
  nullable    = false
  default     = {}
}

variable "cirrus_workflow_definitions_variables_ssm" {
  description = <<-DESCRIPTION
  (Optional) Map of maps to SSM parameter paths used when templating workflow YAML definitions prior to their conversion to HCL. This variable works identically to `cirrus_workflow_definitions_variables` but sources values from AWS Systems Manager Parameter Store instead of static configuration.

  Works identically to `cirrus_task_definitions_variables_ssm` but applies to workflow YAML definitions and state machine JSONs. See that variable's documentation for detailed usage examples and best practices.

  Example structure:
  ```
  {
    example-workflow-1 = {
      callback_queue_arn = "/cirrus/workflows/example-workflow-1/callback-queue-arn"
      callback_queue_url = "/cirrus/workflows/example-workflow-1/callback-queue-url"
    }
    example-workflow-2 = {
      external_api_endpoint = "/cirrus/shared/external-api-endpoint"
    }
  }
  ```
  DESCRIPTION
  type        = map(map(string))
  nullable    = false
  default     = {}
}

variable "cirrus_process_sqs_cross_account_sender_arns" {
  description = "List of AWS principal ARNs from external accounts that should be allowed to send messages to the cirrus process SQS queue"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "domain_alias" {
  description = "Custom domain alias for private API Gateway endpoint"
  type        = string
  default     = ""
}

variable "private_certificate_arn" {
  description = "Private Certificate ARN for custom domain alias of private API Gateway endpoint"
  type        = string
  default     = ""
}
