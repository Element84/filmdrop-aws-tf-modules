<!-- omit from toc -->
# My Project FilmDrop Deployment

- [Development](#development)
- [Pre-deploy setup](#pre-deploy-setup)
- [Deploying](#deploying)
  - [Manually](#manually)
  - [Via GitLab CI](#via-gitlab-ci)
  - [Via GitHub Actions](#via-github-actions)
- [Destroy](#destroy)
  - [Manually](#manually-1)
  - [Via GitLab CI](#via-gitlab-ci-1)
  - [Via GitHub Actions](#via-github-actions-1)

This repository deploys the
[FilmDrop Infrastructure Terraform Modules](https://github.com/Element84/filmdrop-aws-tf-modules).

## Development

Install pre-commit hooks:

```bash
pre-commit install
```

And run them with:

```bash
pre-commit run --all-files
```

## Pre-deploy setup

1. For each of the AWS Accounts to be deployed into, create the bootstrap
   resources as outlined in <bootstrap/README.md>.

## Deploying

### Manually

This section describes how to deploy manually from a non-CI host. This is often
useful when initially trying to configure a deployment. If the S3 backend is used
for Terraform state, the deployment will seamlessly transition to being CI deployed.

By default, Terraform will use a local store for state. If you want to configure
this to use S3 and DynamoDB instead, in the same way a CI build does,
create a file to define the backend named `config.s3.backend.tf` with contents like:

```text
terraform {
  backend "s3" {
    encrypt        = true
    bucket         = REPLACE_ME # with the bootstrapped bucket name
    dynamodb_table = "filmdrop-terraform-state-locks"
    key            = "{project_name}-{username}-test.tfstate" # replace with username
    region         = "us-west-2"
  }
}
```

The `bucket` name will be the value to be set for `TF_STATE_BUCKET`, e.g.,
`filmdrop-{project_name}-{region}-terraform-state-{random_string}`.

Download the filmdrop-aws-tf-modules source:

```shell
./scripts/retrieve_tf_modules.sh v2.24.0
```

Re-run this anytime you with to uptake a new `filmdrop-aws-tf-modules` release,
in addition to updating the env var in `.github/workflows/ci.yaml`.

Run the Terraform commands to initialize, validate, plan, and apply the
configuration:

```shell
terraform init
terraform validate
terraform plan -var-file=dev.tfvars -out tfplan
terraform apply -input=false tfplan
```

If you prefer to use a local state file, delete the `config.s3.backend.tf`
file and run `terraform init` again without it.

### Via GitLab CI

TODO

### Via GitHub Actions

Create a GitHub Environment (e.g., `dev`) with these Environment Secrets:

| Variable              | Description                                             | Example                                                                               |
| --------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `AWS_REGION`          | region to deploy into                                   | `us-west-2`                                                                           |
| `AWS_ROLE`            | the ARN of the AWS Role to use for deploy               | `arn:aws:iam::0123456789:role/appFilmDropDeployRoleBootstrap-DeployRole-Wfx5HwlneOVM` |
| `TF_STATE_BUCKET`     | the bucket use for storing Terraform state              | `filmdrop-{project_name}-{region}-terraform-state-{random_string}`                    |
| `TF_STATE_LOCK_TABLE` | the DynamoDB table to use for Terraform locks           | `filmdrop-terraform-state-locks`                                                      |
| `SLACK_CHANNEL_ID`    | ID of Slack channel to post deploy status notifications | `D26F29X7OB3`                                                                         |
| `SLACK_BOT_TOKEN`     | Slack Bot Token                                         | alphanumeric string                                                                   |

The following GitHub Actions will run under the following situations:

- The validation workflow will run upon any push to any branch. This runs
  some tests on the validity of the Terraform configuration.
- The staging workflow will run upon push to `main` or any tag starting with `v`.
- The prod workflow will run upon push to any tag starting with `v`.

The staging and prod workflows require manual approval to access their respective
GitHub Environments.

## Destroy

### Manually

Run `terraform destroy -var-file=dev.tfvars -input=false`

### Via GitLab CI



### Via GitHub Actions

TODO

