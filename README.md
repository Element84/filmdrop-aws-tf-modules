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

Check out the [changelog](CHANGELOG.md) and [migration steps](MIGRATION.md).

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
filmdrop_ui_url = "https://adifferentid.cloudfront.net"
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
│   with module.filmdrop.module.filmdrop-ui[0].module.cloudfront_s3_website.module.cloudfront_distribution.module.cloudfront_waf[0].aws_waf_rule.fd_waf_ip_block_wafrule,
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
deploy_filmdrop_ui                  = false
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


## License

Copyright 2023 Element 84 <open-source@element84.com>.
Licensed under [Apache-2.0](./LICENSE).
