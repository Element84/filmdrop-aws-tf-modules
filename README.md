<!-- markdownlint-disable MD033 MD041 -->

<p align="center">
  <a href="https://element84.com/filmdrop/" target="_blank">
      <img src="./images/FilmDrop_E84_Combined_Logo.png" alt="FilmDrop by Element 84" class="headerLogoImage filmDrop">
  </a>
  <p align="center">FilmDrop Terraform infrastructure modules for AWS.</p>
</p>
<p align="center">
  <a href="https://github.com/Element84/filmdrop-aws-tf-modules/actions?query=workflow%3AContinuous%20integration" target="_blank">
      <img src="https://github.com/Element84/filmdrop-aws-tf-modules/workflows/Continuous%20integration/badge.svg" alt="Test">
  </a>
  <a href="https://github.com/Element84/filmdrop-aws-tf-modules/actions?query=workflow%3ASnyk%20Scan" target="_blank">
      <img src="https://github.com/Element84/filmdrop-aws-tf-modules/workflows/Snyk%20Scan/badge.svg" alt="Test">
  </a>
  <a href="https://github.com/Element84/filmdrop-aws-tf-modules/releases" target="_blank">
      <img src="https://img.shields.io/github/v/release/Element84/filmdrop-aws-tf-modules?color=2334D058" alt="Release version">
  </a>
  <a href="https://github.com/Element84/filmdrop-aws-tf-modules/blob/main/LICENSE" target="_blank">
      <img src="https://img.shields.io/github/license/Element84/filmdrop-aws-tf-modules?color=2334D058" alt="License">
  </a>
</p>

---

This repository contains the packaging of FilmDrop terraform modules.

Check out the [changelog](CHANGELOG.md).

## Module Documentation

The following modules contain READMEs that may serve as a useful reference when configuring a FilmDrop deployment:
- [cirrus](./modules/cirrus/README.md)

## `flop` CLI

`flop` is a bash script for creating and interacting with FilmDrop test
environments. It was initially built for
[filmdrop-k8s-tf-modules](https://github.com/Element84/filmdrop-k8s-tf-modules)
and has been re-created for this repository.

## Dependencies and Setup

- Bash &nbsp;<sub><sup>(versions tested: 5, 3.2)<sub><sup>
- terraform
- nvm
- tfenv

On Mac, install the two version management dependencies with:

```shell
brew install tfenv nvm
```

-Note: if you already have `terraform` installed, you may need to unlink it
first (`brew unlink terraform`), as the homebrew packages for `tfenv` and
`terraform` are mutually exclusive.*

## AWS configuration

Export temporary AWS keys, by obtaining those credentials via AWS SSO.
The following 4 variables will be needed prior to running the infrastructure code:

```shell
export AWS_ACCESS_KEY_ID=<REPLACE_WITH_AWS_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<REPLACE_WITH_AWS_SECRET_ACCESS_KEY>
export AWS_SESSION_TOKEN=<REPLACE_WITH_AWS_SESSION_TOKEN>
```

Remember to specify your preferred aws region, either by modifying your
credentials or exporting the following environment variable:

```shell
export AWS_DEFAULT_REGION=<REPLACE_WITH_AWS_DEFAULT_REGION>
```

You can alternatively choose create an [AWS credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

## Running FilmDrop Terraform Deployment

Next, initialize the terraform environment of FilmDrop via:

```shell
./flop init
```

The flop init should pull the providers needed to run your terraform code.
Then, validate your FilmDrop terraform code with:

```shell
./flop validate default.tfvars
```

If your terraform is valid, the validate command will respond with `Success! The configuration is valid.`
Test your proposed FilmDrop infrastructure changes with a:

```shell
./flop test default.tfvars
```

The terraform plan will give you a summary of all the changes terraform will
perform prior to deploying any change.

You may choose to customize the default.tfvars or provide your own tfvars for inputs to your deployment.
Create the FilmDrop infrastructure by running:

```shell
./flop create default.tfvars
```

The flop create command will run a terraform apply in the background that will
deploy the changes, but before doing so, terraform will perform an additional
plan and ask you for a confirmation, for which you need to answer `yes` to
proceed with the deployment.

```text
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

Enter a value: yes
```

The deployment will take 25-45 minutes to complete the deployment of the full
FilmDrop stack, and if it succeeds, your FilmDrop environment should be up in
the AWS account!

The output of the deployment should look like:

```text
Outputs:


analytics_url = "https://someid.cloudfront.net"
cirrus_dashboard_url = "https://someotherid.cloudfront.net"
console_ui_url = "https://adifferentid.cloudfront.net"
private_avaliability_zones = tolist([
  "us-west-2c",
  "us-west-2b",
  "us-west-2a",
])
private_subnet_ids = tolist([
  "subnet-xxxxxxxxxxxxxxxxx",
  "subnet-yyyyyyyyyyyyyyyyy",
  "subnet-zzzzzzzzzzzzzzzzz",
])
public_avaliability_zones = tolist([
  "us-west-2b",
  "us-west-2a",
  "us-west-2c",
])
public_subnet_ids = tolist([
  "subnet-xxxxxxxxxxxxxxxxx",
  "subnet-yyyyyyyyyyyyyyyyy",
  "subnet-zzzzzzzzzzzzzzzzz",
])
s3_access_log_bucket = "filmdrop-<environment>-access-logs-xxxxxxxxxxxxxxxxx"
s3_logs_archive_bucket = "filmdrop-<environment>-logs-archive-xxxxxxxxxxxxxxxxx"
security_group_id = "sg-xxxxxxxxxxxxxxxxx"
stac_url = "https://newid.cloudfront.net"
titiler_url = "https://anothernewid.cloudfront.net"
vpc_cidr = "x.x.x.x/x"
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
```

If you would like to take a look at the flop terraform infrastructure outputs again just run:

```text
 ./flop output
```

### Known Deployment Issues

#### Pulling the stac-server Lambda Code

During the deployment, you may see the following error due to how we're pulling
the stac server lambda code at apply time:

```text
│ Error: Provider produced inconsistent final plan
│
│ When expanding the plan for module.filmdrop.module.stac-server[0].module.stac-server.aws_lambda_function.stac_server_ingest to include new values learned so far during apply, provider "registry.terraform.io/hashicorp/aws" produced an invalid new value for
│ .source_code_hash: was cty.StringVal("********"), but now cty.StringVal("********").
│
│ This is a bug in the provider, which should be reported in the provider's own issue tracker.
╵
╷
│ Error: Provider produced inconsistent final plan
│
│ When expanding the plan for module.filmdrop.module.stac-server[0].module.stac-server.aws_lambda_function.stac_server_api to include new values learned so far during apply, provider "registry.terraform.io/hashicorp/aws" produced an invalid new value for
│ .source_code_hash: was cty.StringVal("********"), but now cty.StringVal("********").
│
```

If you see the error above, just run a flop update like:

```text
./flop update default.tfvars
```

The terraform apply will deploy the changes, but before doing so, terraform will
perform an additional plan and ask you for a confirmation, for which you need to
answer `yes` to proceed with the deployment.

```text
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

Enter a value: yes
```

#### Exceeding WAF Limits

AWS's default limit for WAF rule limits is 100 per region per account.
If your account exceeded that limit while deploying, you may see an error message like this:

```text
│ Error: creating WAF Rule (FilmDropWAFIPBlockRulefdtestpjgtestconsole): WAFLimitsExceededException: Operation would result in exceeding resource limits.
│ 
│   with module.filmdrop.module.console-ui[0].module.cloudfront_s3_website.module.cloudfront_distribution.module.cloudfront_waf[0].aws_waf_rule.fd_waf_ip_block_wafrule,
│   on modules/cloudfront/waf/waf_cloudfront.tf line 40, in resource "aws_waf_rule" "fd_waf_ip_block_wafrule":
│   40: resource "aws_waf_rule" "fd_waf_ip_block_wafrule" {
```

In that case, you either need to remove WAF rules from that account, or pick a new account.

## Destroying FilmDrop Terraform Deployment

You can delete your FilmDrop stack by running (reference the same tfvars file
used during the flop create/update or terraform apply):

```shell
./flop destroy default.tfvars
```

or by changing all infrastructure flags to false in your tfvars and performing a terraform apply:

```tf
##### INFRASTRUCTURE FLAGS ####
# To disable each flag: set to 'false'; to enable: set to 'true'
deploy_vpc                          = false
deploy_vpc_search                   = false
deploy_log_archive                  = false
deploy_stac_server                  = false
deploy_analytics                    = false
deploy_titiler                      = false
deploy_console_ui                   = false
deploy_cirrus_dashboard             = false
deploy_local_stac_server_artifacts  = false
deploy_waf_rule                     = false
```

```shell
./flop update default.tfvars
```

The first thing that will happen is that the destroy will try to delete the
stac-server opensearch domain, if one exists. You will need to answer `yes` to
proceed.

```text
We detected a Stac Server OpenSearch Domain fd-hector-demo-stac-server running in flop environment...
Do you really want to destroy the Stac Server OpenSearch domain along with other resources?
There is no undo. Only 'yes' will be accepted to confirm.

Enter a value:
```

Then the flop CLI will perform a terraform plan and ask you to confirm the
destroy of all the resources on the terraform state. You will need to answer
`yes` to proceed.

```text
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```

That's it! After 25-45 minutes (with a full FilmDrop deployment), you should not
see your FilmDrop resources anymore if you log into your AWS account.
To confirm there are no more resources in the FilmDrop Terraform state, you may run:

```shell
./flop list
```

Which should return an empty value.

### Problems with Destroying Your Deployment

Your destroy *may* time out with an error message like this:

```text
│ Error: deleting Security Group (sg-074106eb2528d86f1): DependencyViolation: resource sg-074106eb2528d86f1 has a dependent object
│       status code: 400, request id: 5282df10-4ff1-4b6d-a182-5fc9483017d8
```

This is likely due to the OpenSearch clusters take *a long time* to delete.
Check your OpenSearch domains and see if there's one that is in a "Being
deleted" state — if there is, you just need to wait for that to complete then
re-try your destroy.

## Migration

Document any changes that need to be made by module instances using these modules to uptake
a newer version. For example, if a new required variable is added, this should be documented here.

### Unreleased

- Removes support for VPC creation. To retain the existing VPC resources, manually
  remove them from the Terraform state file. However, you should then create another
  IaC deployment for that VPC.
- `stac_server_inputs` and `titiler_inputs`, renamed
  `stac_server_and_titiler_s3_arns` to `authorized_s3_arns`.
- `titiler_inputs.mosaic_titiler_release_tag` is now `titiler_inputs.version`
- `cirrus_dashboard_inputs.cirrus_dashboard_release` is now `cirrus_dashboard_inputs.version`
- `console_ui_inputs.filmdrop_ui_release` is now `console_ui_inputs.version`
- `deploy_sample_data_bucket` option has been removed

### 2.x

- There were certainly many, but they were not documented.

### 1.7.0

- Remove cirrus_dashboard_release_tag uses in deployment to use new default version of v0.5.1
- Please upgrade to AWS provider `~=5.20`

### 1.6.0

- The jupyterhub-dask-eks module no longer takes a parameter `kubernetes_cluster_name`,
  but now requires a parameter `environment`. Resource names that previously used
  `kubernetes_cluster_name` now construct those using the `project_name` and `environment`
  variables
- The default OpenSearch cluster name has changed to include both
  environment/stage, to allow for multiple deployments to a single AWS account.
  Unfortunately, an OpenSearch cluster name can't be changed after creation, so
  running a TF apply would attempt to destroy the old cluster and create a new
  one. If it is desired to preserve the old cluster (and data) upon taking this
  update, a new optional variable has been added to override the cluster name.
  Setting the input variable `opensearch_stac_server_domain_name_override` to
  match the pre-existing cluster name will allow taking this update to preserve
  the old default name moving forward.

### 1.5.0

- console-ui.filmdrop_ui_release must be gte 4.x, e.g., `v4.0.1`. Along with this,
  the `filmdrop_ui_env` variable should be removed, the .env files deleted, and the
  `VITE_APP_NAME` variable moved to `APP_NAME` in the config json file.

### 1.4.x

- Please upgrade to AWS provider `~=5.13`
- The WAF rules for mosaic titiler have been defined in the mosaic-titler module.  The consumer
  must now pass in an "aws.east" provider because cloudfront requires global resources created in
  us-east-1.  Consumers should set the new "waf_allowed_url" variable to set the WAF rules to enable
  blocking of requests.  Leaving the default of null will set the rules to count only and disable
  blocking.  If the consumer has previous defined a mosaic titiler WAF rule using the "titiler_waf_rules_map"
  variable, this should be removed as it has been replaced with the module's implementation.
- Remove the OpenSearch service linked role from the terraform state with `terraform state rm 'aws_iam_service_linked_role.opensearch_linked_role'`

### 1.3.0

- If your deployment does not use cloudfront in front of stac-server, the stac_api_rootpath variable
  in stac-server/inputs.tf must be set to null.  The default (empty string) is correct for when
  cloudfront is in use.

### 1.2.0

- FilmDrop UI version >= 3.0.0 is now required. Previously, the configuration file was a
  JavaScript file and was placed in `./src/assets/config.js`. It is now a JSON file and is
  placed in `./public/config/config.json`. This change can be seen in
  [this commit](https://github.com/Element84/filmdrop-ui/pull/202/files#diff-06572a96a58dc510037d5efa622f9bec8519bc1beab13c9f251e97e657a9d4ed).
  The primary changes are:
  * The JavaScript const variables are now JSON attribute names.
  * Parameters (JSON attribute names) are no longer prevised by `VITE_`, e.g.,
    `VITE_DEFAULT_COLLECTION` is now `DEFAULT_COLLECTION`
  * Parameters for which you wish to use the default no longer need to be included as null/empty.

## License

Copyright 2023 Element 84 <open-source@element84.com>.
Licensed under [Apache-2.0](./LICENSE).
