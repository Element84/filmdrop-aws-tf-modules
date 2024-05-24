<!-- omit from toc -->
# Deploying FilmDrop via the FilmDrop AWS Terraform Modules

- [Setup](#setup)
- [Git Repository Setup](#git-repository-setup)
- [Boostrap AWS Resources](#boostrap-aws-resources)
  - [Create Deployment IAM Role](#create-deployment-iam-role)
  - [Create OpenSearch Service Service Role](#create-opensearch-service-service-role)
  - [Create Terraform State Backend Resources](#create-terraform-state-backend-resources)
- [Configure CI](#configure-ci)
  - [Update CI Files](#update-ci-files)
  - [CI Configuration - GitLab (Option 1)](#ci-configuration---gitlab-option-1)
  - [CI Configuration - GitHub (Option 2)](#ci-configuration---github-option-2)
- [FilmDrop Terraform Configuration](#filmdrop-terraform-configuration)
  - [Global Configuration](#global-configuration)
  - [VPC Configuration - Use Existing VPC (Option 1) (default)](#vpc-configuration---use-existing-vpc-option-1-default)
  - [VPC Configuration - Create New VPC (Option 2)](#vpc-configuration---create-new-vpc-option-2)
  - [Other configuration](#other-configuration)
  - [Cirrus Configuration](#cirrus-configuration)
  - [Cirrus Dashboard Configuration](#cirrus-dashboard-configuration)
  - [stac-server Configuration](#stac-server-configuration)
  - [Tiler Configuration](#tiler-configuration)
- [Console UI (filmdrop-ui) Configuration](#console-ui-filmdrop-ui-configuration)
- [Analytics Deployment (JupyterHub on EKS)](#analytics-deployment-jupyterhub-on-eks)
- [Deploy](#deploy)
- [After the first deploy](#after-the-first-deploy)
- [Creating the Prod Deployment](#creating-the-prod-deployment)
- [Configuring Authentication](#configuring-authentication)
- [Destroying the Deployment](#destroying-the-deployment)

This document provides details on creating a new FilmDrop deploy project.

The expected development model here is that the deployer will first
create a "dev" environment deployment and deploy that into a "dev" AWS
Account, and then create a "prod" environment deployment to deploy in to
a "prod" AWS Account. Most of the instructions here will need to be
repeated for each environment and AWS Account.

Additional environments can be created by adding a tfvars file and
adding a build and relevant variables for that environment to the GitHub Actions or
GitLab CI file.

## Setup

Choose a 5-8 character "codename" for your project. This will be used as the `project_name`
   variable within the deployment. This could be as generic as `filmdrop`, or
   fun like an animal name, e.g., `stingray`.

Most deployments use CloudFront distributions with a custom URL on a
specific subdomain, rather than accessing services at the default
`cloudfront.net` or `amazonaws.com` URLs.
Identify what subdomain you would like to access your services from.
Typically, non-prod environments like dev will use something like `dev.stingray.example.com`
and prod will use something like `stingray.example.com`

## Git Repository Setup

Create a Git repository for your FilmDrop Infrastructure deployment
project (e.g., `filmdrop-{project_name}-aws-infra-ops`). This will be the
FilmDrop deployment project that will deploy FilmDrop from CI.

Copy the contents of the `project` directory from this
repository to the root of your new repository.

Rename `remove.gitignore` to `.gitignore`

Commit this code to the new repository as the branch `main`. This will start
a pipeline, which will probably fail since we haven't yet performed some required
configuration.

Before making any other changes, create a new branch to put these changes in.

## Boostrap AWS Resources

### Create Deployment IAM Role

The deployment IAM Role is used when deploying FilmDrop infrastructure from CI.
The deployment Role should be created once per AWS Account.

There are two different CloudFormation templates, depending on which CI system
you are using:

- GitLab: bootstrap/gitlab_deploy_role_cfn.yml
- GitHub: bootstrap/github_deploy_role_cfn.yml

You can create a CloudFormation Stack from these templates with the
following command (GitLab example shown), The Terraform state S3 Bucket name
(discussed later) must be globally unique, so it is recommended to use where the value
passed for `TerraformStateBucketName` is a unique bucket name based on the template
`filmdrop-{project_name}-{region}-terraform-state-{random_string}`:

```shell
aws cloudformation deploy --stack-name "appFilmDropDeployRoleBootstrap" \     
   --template-file bootstrap/gitlab_deploy_role_cfn.yml \
   --capabilities=CAPABILITY_NAMED_IAM \
   --parameter-overrides     TerraformStateBucketName=filmdrop-stingray-us-west-2-terraform-state-20240515
```

Copy the Role ARNs created by this deploy and either:

- GitLab: Enable the trust policy for these roles in GitLab Runner. After they
are enabled, GitLab CI pipelines of your project will be able to use
this role to connect to corresponding AWS accounts.
- GitHub: TBD

### Create OpenSearch Service Service Role

The Service Role should be created only once per AWS Account.

OpenSearch requires an IAM Service Role named `AWSServiceRoleForAmazonOpenSearchService` to be defined.

This role is automatically created when creating an OpenSearch Service domain
using the AWS Console, but must be created explicitly when creating a domain
programmatically.

Note that this will fail if the Role already exists, which is fine, since deployment
of the stac-server module only requires that it exists.

To deploy, run:

```shell
cd bootstrap
terraform init
terraform apply -target=aws_iam_service_linked_role.opensearch_linked_role
```

There is no need to keep the terraform state file, as running this is intended to
be an idempotent operation.

### Create Terraform State Backend Resources

Terraform stores the state of the deployment in a managed state file. When deploying via CI
to shared environments, this state file must be stored somewhere non-local, so we use
S3. This sets up an S3+DynamoDB Terraform backend to store this state. This
should be created once per AWS Account + Region.

```text
filmdrop-myProjectAccount-us-west-2-terraform-state-96842
```

The Dynamo DB Table name defaults to `filmdrop-terraform-state-locks`.

Deploy these resources through CloudFormation with the following command:

```shell
aws cloudformation deploy --stack-name appFilmDropTerraformStateBootstrap \
   --template-file terraform_state_cfn.yml
   --parameter-overrides     TerraformStateBucketName=filmdrop-stingray-us-west-2-terraform-state-20240515
```

Once deployed, you'll need the S3 Bucket name and DynamoDB table name to configure the
Terraform backend. You'll add those values to the FilmDrop infrastructure project later.

## Configure CI

### Update CI Files

### CI Configuration - GitLab (Option 1)

The .gitlab-ci.yml contains jobs to validate and deploy to different environments. The
job names starting with a `.` are "abstract" jobs that are intended to be reusable by
"concrete" jobs, for example, `validate_and_plan_dev` is a concrete job that extends
`.validate_and_plan` and `.dev_variables`, thereby running the `script` statements in
`.validate_and_plan` with the environment variables defined in `.dev_variables`.

Edit the .gitlab-ci.yml file according to the following.

For:

```text
default:
  image: REPLACEME
```

Set `REPLACEME` to a Docker image URI that has the following tools installed:

- Python 3.11
- Node 18
- Terraform 1.7.5
- pre-commit

Optionally, [snyk](https://github.com/snyk/cli) should be installed and configured
or those commands should be removed from build.

This may require creating, building, and pushing and image yourself.

Under the .common_variables/variables section, configure the variables:

- `PROJECT_NAME`: change to the value chosen during Git Repository Setup
- `AWS_DEFAULT_REGION` and `AWS_REGION`: Terraform uses these settings to configure
  which region to deploy to. Change if deploying to a region other than us-west-2
- `FILMDROP_DEPLOY_ROLE_NAME`: change if it is different than the default value of `appFilmDropDeployRole`
- `STAC_SERVER_TAG`: Update if there is a different version of stac-server that you wish to use

Under the .dev_variables/variables, configure the variables:

- `FILMDROP_TERRAFORM_RELEASE`: the [filmdrop-aws-tf-modules](https://github.com/Element84/filmdrop-aws-tf-modules/releases)
  version to use
- `ENVIRONMENT`: The enviroment this is deploying to, e.g., Development, Staging, Production
- `STAGE`: Same as the environment, but a shorter, lowercase version, e.g., dev, staging, prod
- `AWS_ACCOUNT_ID`: The AWS Account Id to deploy into
- `AWS_ROLE_ARN`: The IAM Role to deploy with, constructed dynamically from the
  `AWS_ACCOUNT_ID` and `FILMDROP_DEPLOY_ROLE_NAME` variables
- `TERRAFORM_STATEFILE`: Name of statefile for this deploy, typically does not need to be changed
- `CONSOLE_URL`: The URL that the Console will be deployed as, to populate the GitLab CI
  deployment card.

Comment out the jobs ending with `_prod` until you want to create and deploy a prod
environment (e.g., after you've successfully deploy the dev environment and configured prod).

By default, merging changes to `main` will deploy to the `dev` environment.

### CI Configuration - GitHub (Option 2)

In deploy-wf.yml:

- update my-project-name to the project codename.
- update RepoOrg/RepoName to the GitHub repo this project will be stored in.

## FilmDrop Terraform Configuration

### Global Configuration

Update the `dev.tfvars` (or other {environment}.tfvars) file and replace the
placeholder values indicated with `REPLACEME` with the values for your deployment.

Length restrictions for some of these settings are so that the total chars in the
`project_name` and `environment` must be \<= 20 chars, so that AWS resource name length
limits are not exceeded.

Update these configuration parameters:

-`environment` - the environment that is being deployed to,
   must be \<= 7 chars, e.g., `dev`, `prod`, `staging`
-`project_name` - a unique, identifying project name \<= 8
   chars, usually a codename, e.g., `stingray`
-`domain_zone` - identify the domain you want to use for vanity urls, and set this
   to the Route 53 zone, e.g., `Z1285324J1INA83NGEZL`
-`s3_access_log_bucket` - TBD
-`s3_logs_archive_bucket` - TBD

### VPC Configuration - Use Existing VPC (Option 1) (default)

It is preferred to use an existing VPC, ideally one deployed from Control Tower.
In the Infrastructure Flags section, set these variables:

```text
deploy_vpc                               = false
deploy_vpc_search                        = true
```

TBD: how does it find the existing VPC?

With `deploy_vpc_search` enabled and the Networking Variables unset, the Terraform
deployment will attempt to query AWS resources to discover the VPC and its associated
resources.

If these settings cannot be discovered, they will need to be configured explicitly,
matching the configuration of the existing VPC, for example:

```text
##### Networking Variables #####
vpc_id            = "vpc-0b68042e52b4b883b"
vpc_cidr          = "10.77.0.0/16"
security_group_id = "sg-01ca36967bdc27d"
public_subnets_az_to_id_map = {
  "us-west-2a" = "subnet-a44771888183d403c"
  "us-west-2b" = "subnet-283630146c3283630"
  "us-west-2c" = "subnet-a0ad053904e4e665a"
}
private_subnets_az_to_id_map = {
  "us-west-2a" = "subnet-343ca36967bdc27df"
  "us-west-2b" = "subnet-30146c332a612b5cf"
  "us-west-2c" = "subnet-b04cc58283630146c
"
}
```

### VPC Configuration - Create New VPC (Option 2)

Before looking to create the new VPC infrastructure, please check if
there is already any existing VPC in your environment that can be used
to deploy the FilmDrop components into. If so, follow the
follow "Use Existing VPC" section.

If a new VPC is required to be created, then the VPC infrastructure
module can be used to create the resources as VPC, Subnets, Internet
Gateway, NAT Gateway, VPC endpoints, etc.

The module supports creating multiple NAT Gateways and corresponding
route table associations in case of a production like environment or
Single NAT Gateway in case of a general non-prod-like environment.

To deploy a VPC, edit tfvars to set:

```text
deploy_vpc                               = true
deploy_vpc_search                        = false
```

and configure it with:

```text
vpc_id            = ""
vpc_cidr          = "10.26.0.0/18"
security_group_id = ""
public_subnets_az_to_id_map = {
  "us-west-2a" = "10.26.0.0/22"
  "us-west-2b" = "10.26.4.0/22"
  "us-west-2c" = "10.26.8.0/22"
}

private_subnets_az_to_id_map = {
  "us-west-2a" = "10.26.12.0/22"
  "us-west-2b" = "10.26.16.0/22"
  "us-west-2c" = "10.26.20.0/22"
}
```

The variables `vpc_id` and `security_group_id` are unset, so Terraform will determine these
from the AWS resources that are deployed.

### Other configuration

Next, configure whether or not to deploy the other FilmDrop Infrastructure modules:

Infrastructure Flags:

- `deploy_log_archive`: TBD
- `deploy_alarms`: TBD

SSM Bastion:

- `ssm_bastion_input_map`: TBD

Alarm Variables:

- `sns_topics_map`: TBD
- `cloudwatch_warning_alarms_map`: TBD
- `cloudwatch_critical_alarms_map`: TBD
- `sns_warning_subscriptions_map`: TBD
- `sns_critical_subscriptions_map`: TBD

### Cirrus Configuration

Cirrus will be deployed if `deploy_cirrus` is enabled:

```text
deploy_cirrus = true
```

This module can be configured to set the data and payload bucket with:

```text
cirrus_inputs = {
  data_bucket    = "fd-{project_name}-{stage}-cirrus-data-{random_string}"
  payload_bucket = "fd-{project_name}-{stage}-cirrus-payloads-{random_string}"
  ...
}
```

### Cirrus Dashboard Configuration

Infrastructure Flags:

```text
deploy_cirrus_dashboard                  = true
```

Application Variables:

Under `cirrus_dashboard_inputs`:

- `version`: the release of [cirrus-dashboard](https://github.com/cirrus-geo/cirrus-dashboard)
  to deploy. This should be updated regularly to deploy the latest version.
- `deploy_cloudfront`: deploy a CloudFront distribution for this service. This is necessary
  for setting a domain alias.
- `domain_alias`: a custom domain to use as the URL for the service, e.g., `dashboard.stingray.dev.example.com`

### stac-server Configuration

**NOTE** If **not** deploying stac-server, the GitLab CI section starting with
"Building stac-server" should be commented out.

Infrastructure Flags:

- `deploy_stac_server`: deploy stac-server using a "classic" OpenSearch cluster.
- `deploy_stac_server_opensearch_serverless`: use OpenSearch Serverless for stac-server's
  backend instead of a "classic" OpenSearch cluster.
- `deploy_stac_server_outside_vpc`: deploy stac-server Lambdas outside the VPC.
- `deploy_local_stac_server_artifacts`: deploy local artifacts, for example, custom pre-hook

Application Flags:

In `stac_server_inputs`:

- `version`: the release of [stac-server](https://github.com/stac-utils/stac-server)
  to deploy. This should be updated regularly to deploy the latest version. Note that when
  upgrading, the GitLab CI build variable `STAC_SERVER_TAG` should also be updated.
- `deploy_cloudfront`: deploy a CloudFront distribution for this service. This is necessary
  for setting a domain alias.
- `domain_alias`: the domain name to use for the STAC API server, e.g., `stac.stingray.dev.example.com`
- `authorized_s3_arns`: S3 ARNs for buckets that the tiler should be granted access.
  This is commonly used to give access to public requester pays buckets.
- `cors_origin`: set to the protocol and domain name of the
  Console UI, e.g., `https://console.dev.stingray.example.com`

### Tiler Configuration

Infrastructure Flags:

- `deploy_titiler`: deploy [titiler-mosaicjson](https://github.com/Element84/titiler-mosaicjson)
  for the Console UI to use for dynamic imagery tiling.

Application Flags:

In `titiler_inputs`:

- `version`: the release of [titiler-mosaicjson](https://github.com/Element84/titiler-mosaicjson)
  to deploy. This should be updated regularly to deploy the latest version.
- `deploy_cloudfront`: deploy a CloudFront distribution for this service. This is necessary
  for setting a domain alias.
- `domain_alias`: the domain name to use for the TiTiler server, e.g., `titiler.dev.stingray.example.com`
- `authorized_s3_arns`: S3 ARNs for buckets that the tiler should be granted access.
  This is commonly used to give access to public requester pays buckets.
- `mosaic_titiler_waf_allowed_url`: the project's stac-server URL
- `mosaic_titiler_host_header`: the titiler domain, e.g., `titiler.dev.stingray.example.com`
  This will be the same value as `domain_alias` if it is set, otherwise it will be an API
  Gateway URL that can only be configured after the first deployment

## Console UI (filmdrop-ui) Configuration

Infrastructure Flags:

- `deploy_console_ui`: deploy the FilmDrop Console UI
  ([filmdrop-ui](https://github.com/Element84/filmdrop-ui))
  for STAC catalog search and visualization.

Application Flags:

- `version`: the release of [filmdrop-ui](https://github.com/Element84/filmdrop-ui)
  to deploy. This should be updated regularly to deploy the latest version.
- `deploy_cloudfront`: deploy a CloudFront distribution for this service. This is necessary
  for setting a domain alias.
- `domain_alias`: the domain name to use for the Console UI, e.g., `console.stingray.dev.example.com`
- `filmdrop_ui_config_file`: the location of the config json,
  e.g., `./console-ui/config.dev.json` or `./console-ui/config.prod.json`
- `filmdrop_ui_logo_file`: the location of the logo file, e.g., `./console-ui/logo.png`

Update the configuration in the config.dev.json file:

-`APP_NAME`: the HTML title to show for the console, e.g., "Stringray FilmDrop Console"
-`PUBLIC_URL`: set to the API Gateway, CloudFront, or domain alias URL of Console UI
-`STAC_API_URL`: set to the API Gateway, CloudFront, or domain alias URL of the stac-server
-`SCENE_TILER_URL`: URL for TiTiler, e.g., `https://titiler.dev.stingray.example.com`
-`MOSAIC_TILER_URL`: URL for TiTiler, e.g., `https://titiler.dev.stingray.example.com`
-`DASHBOARD_BTN_URL`: URL for Cirrus Dashboard, e.g., `https://dashboard.dev.stingray.example.com`
-`ANALYZE_BTN_URL`: URL for Analytics, e.g., `https://analytics.dev.stingray.example.com`

## Analytics Deployment (JupyterHub on EKS)

**Optional:** this is going to be replace with a hosted solution, as it
doesn't work in a production-friendly way.

Infrastructure Flags:

- `deploy_analytics`: Deploy JupyterHub

Application Flags:

If deploying to a custom domain, from AWS console, create a cert to
be used for JuptyerHub ELB and obtain the cert ARN, then set these
variables in `analytics_inputs`:

- `domain_alias` with the alias
- `jupyterhub_elb_acm_cert_arn` with cert ARN
- `jupyterhub_elb_domain_alias` with your domain alias for Jupyterhub

Wait while the deploy builds the daskhub docker image. Deploy
doesn't create the EKS cluster directly, but instead creates a
CodeBuild project that builds a docker image for Dask (named
starting with `daskhub-dkr-img`) and deploying JupyterHub via EKS
(named `fd-analytics-{project_name}-{environment}-build`), so it
takes some time.

## Deploy

Commit all changes and push to your branch. This should initiate a CI pipeline,
with a manual option to approval deploying to `dev`. Debug any failures in the
pre-deploy jobs, and then attempt a deploy. Don't worry if this doesn't work the
first time! There are a lot of configurations to get correct, and these instructions
probably have something wrong too.

The deployment will deploy many AWS resources, so it can take a while. Many resources are
created in parallel, but there are some resources which block progress for a significant
amount of time. The operations which take the most time are:

- VPC - 10 minutes
- stac-server OpenSearch cluster - 30 to 60 minutes
- CloudFront distributions for each service - 5 to 10 minutes each

## After the first deploy

After the Terraform deploy completes, wait for the
`fd-analytics-{project_name}-{environment}-build` CodeBuild project to succeed. If a
run of that project has not started, deploy again to start it.

Now that Cirrus is deployed, the `cirrus_dashboard_inputs` can be updated with the
API Gateway endpoints for it:

- `cirrus_api_endpoint`: The Cirrus API endpoint, e.g.,
  `https://skdjwnvn7xp.execute-api.us-west-2.amazonaws.com/dev`. Must be configured after
  the initial deploy.
- `metrics_api_endpoint`: Typically the Cirrus API endpoint with `/stats` appended.

In order to have the correct workflows display on the Cirrus
Dashboard, you need to create a file named `catalog.json` and
manually upload it to the `cirrus-{stage}-data-{random}` S3 Bucket
created by the Cirrus deploy. TODO: example file
The configuration for the `workflows` parameter
has attributes with the names of input_collections and workflow from
each workflow that runs. These correspond to the `id` values that
the payloads are given, so for a task that expects IDs like
`usgs-landsat-c2l1/workflow-hls-landsat-tile/test3`, there would be
a key added to the `workflows` object like
`"usgs-landsat-c2l1": ["hls-landsat-pathrow"]`. Each workflow should
be added to catalog.json for it to appear in the Dashboard workflows
view.

The `stac_server_inputs` can be updated to connect stac-server to Cirrus by setting the
variable `ingest_sns_topic_arns` list to include the Cirrus Publish SNS Topic
ARN. This will look like `arn:aws:sns:us-west-2:01234567890:cirrus-stingray-dev-publish` and can
be found by browsing the created SNS Topics in the AWS Console.

The OpenSearch cluster configuration defaults are as small (and cheap) as allowed, but
are typically undersized for any real use. These will need to be increased in size
when the deployment is actually going to be used.

A good starting configuration is to use `m5.large.search` nodes for both
`opensearch_cluster_instance_type` and `opensearch_cluster_dedicated_master_type`
and set `opensearch_ebs_volume_size` to 100 GB.

As STAC Items are ingested into stac-server, the Console UI configuration should be
updated with configuration to appropriately display the collection items.

## Creating the Prod Deployment

To create a new production deploy, copy your `dev.tfvars` file to `prod.tfvars`
and make the following changes:

- Change `environment` to `prod`
- Change the stac-server OpenSearch cluster configuration to enable a larger cluster, e.g.:
  - `opensearch_cluster_instance_type` = "m5.large.search"
  - `opensearch_cluster_dedicated_master_type` = "m5.large.search"
  - Additionally, the `opensearch_cluster_instance_count` parameter can be increased
    from 3 to another multiple of 3. It is generally recommended that to scale, the
    instance type be made larger first (up to 64GB instances), and then the number of nodes increased.

- To deploy to prod, tag `main` with a CalVer version like
  `v2023.02.09` and push the tag. This will create a pipeline for
  deploy in GitLab. The final step to deploy must be invoked manually
  from the GitLab pipeline.

## Configuring Authentication

Basic Authentication can be configured for STAC Server, Console UI, TiTiler, Cirrus Dashboard,
and Analytics. Basic Authentication is configured by default for STAC Server and
Console UI. Because Console UI, stac-server, and TiTiler talk to each other, it
is necessary to configure them in concert, however, currently it is not possible
to have dynamic imagery display on the map when basic auth is configured.

After deploying, a CloudFront Function will be created that performs the basic auth validation
with a suffix of `basicauth-function`. Each Function will have an associated KeyValueStore.
Within each, create a key value pair with the key `credentialsList` and a value of a
comma-separated list of valid `Authorization` headers. These the template for these headers
is `Basic {base-64 encoded username:password}`, e.g., for the username and password
combination `Aladdin:open sesame`, a single entry would be `Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==`.

For STAC Server, modify the `stac_server_inputs` variable `auth_function` like:

```text
auth_function = {
  ...
  attach_cf_function           = false
  ...
  create_cf_function           = false
  create_cf_basicauth_function = false
  ...
}
```

To support Console UI accessing it, also configure the `stac_server_inputs` configurations:

- `cors_origin`: change from the default of `"*"` to the protocol and domain name of the
  Console UI, e.g., `https://console.dev.stingray.example.com`
- `cors_credentials`: set to `true`

For Console UI, modify the `console_ui_inputs` variable `auth_function` like:

```text
auth_function = {
  ...
  attach_cf_function           = false
  ...
  create_cf_function           = false
  create_cf_basicauth_function = false
  ...
}
```

Additionally modify the `config.dev.json` file to set `FETCH_CREDENTIALS` to `include`. This
configures Console UI to send the same basic auth credentials sent to it to the `fetch`
requests to STAC Server.

For TiTiler, modify the `titiler_inputs` variable `auth_function` like:

```text
auth_function = {
  ...
  attach_cf_function           = false
  ...
  create_cf_function           = false
  create_cf_basicauth_function = false
  ...
}
```

For Cirrus Dashboard, modify the `cirrus_dashboard_inputs` variable `auth_function` like:

```text
auth_function = {
  ...
  attach_cf_function           = false
  ...
  create_cf_function           = false
  create_cf_basicauth_function = false
  ...
}
```

For Analytics, modify the `analytics_inputs` variable `auth_function` like:

```text
auth_function = {
  ...
  attach_cf_function           = false
  ...
  create_cf_function           = false
  create_cf_basicauth_function = false
  ...
}
```

## Destroying the Deployment

- If jupyterhub-dask-eks module is deployed:
  - manually delete the EKS cluster (e.g.,
    `fd-{project_name}-{environment}-analytics`). This will take
    minutes to delete.
  - Delete JupyterHub EKS secrets
    `fd-{project_name}-{environment}-admin-credentials` and
    `fd-{project_name}-{environment}-dask-tokens`
  - Delete S3 bucket
    `fd-analytics{project_name}-{environment}-jupyter-config-{random_id}`
  - Delete JupyterHub ELBs

- If stac-server module is deployed, manually delete the OpenSearch
  cluster, e.g., `stac-server-dev`). This may take up to an hour to
  delete.

- `terraform destroy -var-file=dev.tfvars -input=false`

Sometimes, the VPC deletion hangs -- if this is happens, go in and
manually delete the VPC and associated resources from the AWS Console, and then re-run
terraform destroy.
