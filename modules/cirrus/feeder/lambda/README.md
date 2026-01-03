## WIP

Work in progress. The intent is to provide a generic Lambda module that can be used by cirrus resources which
adhere to a common type definition; currently, both feeder and task Lambdas do so.

Rather than duplicate Lambda-related resource configuration in /cirrus/task and /cirrus/feeder, the hope is that
this module can be used by both. See Issue #212 for more detail

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Lambda function name. Auxillary resources will be prefixed with this. | `string` | n/a | yes |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | List of subnet ids in the target VPC that the lambda resources should be connected to. | `list(string)` | n/a | yes |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of security groups in the target VPC that the lambda resources should use. | `list(string)` | n/a | yes |
| <a name="input_lambda_config"></a> [lambda\_config](#input\_lambda\_config) | The standard config for Cirrus Task and Feeder Lambdas. See the /cirrus/task/README.md for full details.<br/><br/>Note: if possible, reusing this module for both tasks and feeders may be beneficial, moving the documentation of the lambda\_config here centrally. | <pre>object({<br/>    description               = optional(string)<br/>    ecr_image_uri             = optional(string)<br/>    resolve_ecr_tag_to_digest = optional(bool)<br/>    filename                  = optional(string)<br/>    image_config = optional(object({<br/>      command           = optional(list(string))<br/>      entry_point       = optional(list(string))<br/>      working_directory = optional(string)<br/>    }))<br/>    s3_bucket            = optional(string)<br/>    s3_key               = optional(string)<br/>    handler              = optional(string)<br/>    runtime              = optional(string)<br/>    timeout_seconds      = optional(number)<br/>    memory_mb            = optional(number)<br/>    ephemeral_storage_mb = optional(number)<br/>    publish              = optional(bool)<br/>    architectures        = optional(list(string))<br/>    env_vars             = optional(map(string))<br/>    vpc_enabled          = optional(bool)<br/>    role_statements = optional(list(object({<br/>      sid           = string<br/>      effect        = string<br/>      actions       = list(string)<br/>      resources     = list(string)<br/>      not_actions   = optional(list(string))<br/>      not_resources = optional(list(string))<br/>      condition = optional(object({<br/>        test     = string<br/>        variable = string<br/>        values   = list(string)<br/>      }))<br/>      principals = optional(object({<br/>        type        = string<br/>        identifiers = list(string)<br/>      }))<br/>      not_principals = optional(object({<br/>        type        = string<br/>        identifiers = list(string)<br/>      }))<br/>    })))<br/>    alarms = optional(list(object({<br/>      critical            = bool<br/>      statistic           = string<br/>      metric_name         = string<br/>      comparison_operator = string<br/>      threshold           = number<br/>      period              = optional(number, 60)<br/>      evaluation_periods  = optional(number, 5)<br/>    })))<br/>  })</pre> | n/a | yes |
| <a name="input_lambda_env_vars"></a> [lambda\_env\_vars](#input\_lambda\_env\_vars) | Map of environment variables to set in the lambda function. Note that lambda\_config.env\_vars allows for a map of environment variables to be set as well; if both are provided, the maps will be merged. lambda\_config.env\_vars is intended for user-provided environment variables via the definition.yaml config). This variable is intended for environment variables that are required for the lambda to function properly, and thus are set at the module level. | `map(string)` | `null` | no |
| <a name="input_warning_sns_topic_arn"></a> [warning\_sns\_topic\_arn](#input\_warning\_sns\_topic\_arn) | SNS topic to be used by all `warning` alarms.<br/><br/>If any non-critical alarms are configured via `var.lambda_config.alarms`, they will use this SNS topic for their alarm action. | `string` | `null` | no |
| <a name="input_critical_sns_topic_arn"></a> [critical\_sns\_topic\_arn](#input\_critical\_sns\_topic\_arn) | SNS topic to be used by all `critical` alarms.<br/><br/>If any critical alarms are configured via `var.lambda_config.alarms`, they will use this SNS topic for their alarm action. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Lambda role name. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Lambda function name. |
<!-- END_TF_DOCS -->
 