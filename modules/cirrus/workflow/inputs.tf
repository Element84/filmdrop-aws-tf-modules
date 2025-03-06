variable "resource_prefix" {
  description = "String prefix to be used in every named resource"
  type        = string
  nullable    = false
}

variable "cirrus_tasks" {
  description = <<-DESCRIPTION
  (optional, map[object]) A map of the 'task' module outputs. These are used for
  variable interpolation in the Workflow state machine definition template. This
  should be set in the parent module and not by user input.
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
}

variable "workflow_config" {
  # NOTE: type changes here require changes in the typed-definitions module, too
  description = <<-DESCRIPTION
    (required, object) Defines a single Cirrus Workflow.
    Contents:
      - name: (required, string) Identifier for the Cirrus Workflow. Must be
        unique across all Cirrus Workflows. Valid characters are: [A-Za-z0-9-]

      - state_machine_filepath: (required, string) Path to an Amazon State
        Machine definition template file. The path must be relative to the ROOT
        module of the Terraform deployment. The template should use valid Amazon
        States Language syntax; wherever a Cirrus Task resource ARN is needed, a
        Terraform interpolation sequence (a "$\{...}" without the "\") may be
        used instead. The interpolation sequence must have the following form:
        ```
          tasks.<TASK NAME>.<TASK TYPE>.<TASK ATTR>
        ```

        Where:
          tasks       : namespace for Cirrus task outputs
          <TASK NAME> : name of the task
          <TASK TYPE> : one of [lambda, batch]
          <TASK ATTR> : one of [function_arn, job_definition_arn, job_queue_arn]

        Example template snippet:
        ```json
          "States": {
            "FirstState": {
              "Type": "Task",
              "Resource": "$\{tasks.my-task.lambda.function_arn}",  // REMOVE THE "\"
              "Next": "SecondState",
              ...
            },
        ```

        For references to environment-specific resources that are not managed by
        Cirrus, such as an SQS queue, an interpolation sequence can be used if
        you have a corresponding entry in the 'workflow_definitions_variables'
        input map. See that variable's description for an example of this.

      - role_statements: (optional, list[object]) List of IAM statements
        to be applied to the workflow's IAM role. Note that this role can
        already submit batch jobs and invoke lambda functions that are
        referenced in the state machine JSON, so you do not need to specify
        those permissions and may omit this setting if these default permissions
        are acceptable. If you will be invoking any additional AWS services,
        however, you must allow the necessary actions through a role statement.

        IMPORTANT - IAM permissions work both ways; you may need to ensure the
        target AWS resource grants the generated workflow IAM role the necessary
        permissions (such as an SQS policy that allows the 'sqs:SendMessage'
        action). This module will output the workflow role's ARN after the first
        successful deployment. If you delete and re-create the workflow for any
        reason, you will need to update any downstream permissions, too, even if
        the workflow role's name/ARN is the same:
        https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-unique-ids

        This object is used to create an 'aws_iam_policy_document' data source.
        Refer to the documentation for more information on the available
        arguments in an IAM statement block:
        https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
  DESCRIPTION
  type = object({
    name                   = string
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
  })

  # Value must be provided else this module serves no purpose
  nullable = false
}

variable "workflow_definitions_variables" {
  description = <<-DESCRIPTION
  (optional, map[map[str]]) Map of maps to strings used when templating state
  machine JSONs. Useful for abstracting environment-specific values away from
  the state machine JSON. This is only needed if your workflow's state machine
  will be using AWS services/resources that are unrelated to Cirrus tasks. One
  such example would be the callback task functionality provided by
  "arn:aws:states:::sqs:sendMessage.waitForTaskToken" state machine resources.

  If your state machine does not invoke any non-cirrus task resources, you do
  not need to use this.

  The suggested (but not explicitly required) structure of this map is to group
  template variables by their workflow name:
  ```hcl
    {
      example-workflow-1 = {
        callback_sqs_queue_arn = "dev-some-sqs-queue-arn"
        callback_sqs_queue_url = "https://..."
      }
      example-workflow-2 = {
        non_task_resource_arn = "dev-some-resource-arn"
        ...
      }
      ... other workflow maps ...
    }
  ```

  Your workflow state machine JSONs would leverage this templating by using an
  attribute lookup in an interpolation sequence $\{...} like so (remove "\"):
  ```json
    {
      "Type": "Task",
      "Resource": "arn:aws:states:::sqs:sendMessage.waitForTaskToken",
      "Parameters": {
          "QueueUrl": "$\{example-workflow-1.callback_sqs_queue_url}", # remove the \
          "MessageBody": {
              "Message": "Hello from Step Functions!",
              "TaskToken.$": "$$.Task.Token"
          }
      },
      "Next": "NEXT_STATE"
    }
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
