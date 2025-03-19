variable "resource_prefix" {
  description = "String prefix to be used in every named resource"
  type        = string
  nullable    = false
}

variable "workflow_config" {
  # NOTE: type changes here require changes in the typed-definitions module, too
  description = <<-DESCRIPTION
  Defines a single cirrus workflow.

  `name`: Identifier for the cirrus workflow. Must be unique across all cirrus workflows. Valid characters are: `[A-Za-z0-9-]`.

  `state_machine_filepath`: Path to an Amazon State Machine definition template file. The path must be relative to the ROOT module of the Terraform deployment. The template should use valid Amazon States Language syntax; wherever a Cirrus Task resource ARN is needed, a Terraform interpolation sequence (`$${...}`) may be used instead. The interpolation sequence must have the following form:
  ```
  tasks.TASK-NAME.TASK-TYPE.TASK-ATTR
  ```

  Where:
  ```
  tasks     : static namespace for cirrus task outputs
  TASK-NAME : name of the cirrus task
  TASK-TYPE : one of [lambda, batch]
  TASK-ATTR : one of [function_arn, job_definition_arn, job_queue_arn]
  ```

  Example template snippet:
  ```
  "States": {
    "FirstState": {
      "Type": "Task",
      "Resource": "\$${tasks.my-task.lambda.function_arn}",
      "Next": "SecondState",
      ...
    },
    ...
  ```

  For references to environment-specific resources that are not managed by cirrus, such as an SQS queue, an interpolation sequence (`$${...}`) can be used if you have a corresponding entry in the `var.workflow_definitions_variables` input map. See that variable's description for an example of this.

  `role_statements`: List of IAM statements to be applied to the workflow's IAM role. Note that this role can already submit batch jobs and invoke lambda functions that are referenced in the state machine JSON, so you do not need to specify those permissions and may omit this setting if these default permissions are acceptable. If you will be invoking any additional AWS services, however, you must allow the necessary actions through a role statement. This list of objects is used to create a `aws_iam_policy_document` terraform data source. Refer to that data source's [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) for more information on the available arguments.

  IMPORTANT - IAM permissions work both ways; you may need to ensure the target AWS resource grants the generated workflow IAM role the necessary permissions (such as an SQS policy that allows the `sqs:SendMessage` action). This module will output the workflow role's ARN after the first successful deployment. If you delete and re-create the workflow for any reason, you will need to update any downstream permissions, too, even if the workflow role's name/ARN is the same due to how [IAM identifiers work](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-unique-ids).
  DESCRIPTION
  type = object({
    name = string

    state_machine_filepath = string

    role_statements = optional(list(object({
      sid           = string
      effect        = string
      actions       = list(string)
      resources     = list(string)
      not_actions   = optional(list(string))
      not_resources = optional(list(string))
      condition = optional(object({
        test     = string
        variable = string
        values   = list(string)
      }))
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      not_principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
    })))
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  })
  # The `~~~~` comment above is to ensure the markdown table column generated
  # by terraform-docs is wide enough for the object schema to be readable.

  # Value must be provided else this module serves no purpose
  nullable = false
}

variable "cirrus_tasks" {
  description = <<-DESCRIPTION
  (Optional) A map of the `task` module outputs keyed by their task's `name`. These are used for variable interpolation in the workflow state machine definition template.
  DESCRIPTION

  type = map(object({
    lambda = object({
      function_arn = optional(string)
    })
    batch = object({
      job_queue_arn      = optional(string)
      job_definition_arn = optional(string)
    })
  }))

  # Tasks aren't technically needed if the user's workflow JSON template doesn't
  # reference any variables, though this is unlikely.
  nullable = true
  default  = null
}

variable "workflow_definitions_variables" {
  description = <<-DESCRIPTION
  (Optional) Map of maps to strings used when templating workflow state machine JSON definitions prior to machine creation. Intended for abstracting environment-specific values away from the state machine JSON.

  This is only needed if your workflow's state machine will be using AWS services/resources that are unrelated to the cirrus tasks created by this module. One such example would be a workflow that leverages the callback task functionality provided by an `arn:aws:states:::sqs:sendMessage.waitForTaskToken` state machine resource that varies by environment.

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

  A `State` within your workflow state machine JSON would look something like this:
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

  If `null` or `{}`, templating will technically still occur but nothing will be interpolated (provided your state machine JSON is also absent of interpolation sequences).
  ```
  DESCRIPTION
  type        = map(map(string))
  nullable    = false
  default     = {}

  validation {
    condition     = (!contains(keys(var.workflow_definitions_variables), "tasks"))
    error_message = <<-ERROR
    The 'workflow_definitions_variables' variable cannot contain 'tasks' as a
    top-level map key; this key is reserved for namespacing Cirrus task outputs.
    ERROR
  }
}

variable "builtin_workflow_definitions_variables" {
  description = <<-DESCRIPTION
  (Optional) Similar to `var.workflow_definitions_variables` but for passing predefined builtin variables, such as `CIRRUS_DATA_BUCKET`, that are set in the `cirrus` module. These are used for templating the workflow state machine JSON.

  This can't be merged with the user-defined `var.workflow_definitions_variables` in the `cirrus` module and passed as a single variable because the two maps may have differing structures/types, which terraform does not allow.
  DESCRIPTION
  type        = map(string)
  nullable    = false
  default     = {}
}
