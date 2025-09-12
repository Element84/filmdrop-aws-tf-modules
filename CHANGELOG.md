# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Added back support for deploying with custom Cirrus lambda zip

### Changed

### Fixed

### Removed

## [2.54.0] - 2025-09-10

### Added

- Added inputs to configure stac-server with enable_collections_authx (stac-server>=v4.4.0)
- Added support for cirrus tasks with mutable tags

### Changed

- Moved Cirrus task related permissions into separate IAM policy

## [2.53.0] - 2025-09-05

### Added

- Added to TF outputs mapping of Cirrus lambda/batch tasks to IAM role arns
- Added CIRRUS_PAYLOAD_BUCKET as builtin template variable
- Added CIRRUS_DATA_BUCKET to parameter store

### Changed

- Download specified version of Cirrus lambda zip from GitHub during deployment

## [2.52.0] - 2025-08-01

### Added

- Support for Cirrus template variables sourced from SSM parameters

## [2.51.0] - 2025-07-25

### Added

-  Support for External AWS accounts Publish to Cirrus Proccess Queue

## [2.50.0] - 2025-07-17

### Changed

- Updated Pangeo base image for Daskhub from 2022 to 2025 with dependency locking

### Added

- stac-server configurations for items_max_limit and enable_response_compression

## [2.49.0] - 2025-06-04

### Added

- Outputs for the stac-server ingest and api lambda functions including their name and arn

## [2.48.0] - 2025-05-21

### Fixed

- Reverting unintended `filmdrop_ui_config_file` and `filmdrop_ui_logo_file` default value changes from the inputs.tf

## [2.47.0] - 2025-05-16

### Added

- Support for PRIVATE-type TiTiler API Gateways
- Added Custom Domain Name support for TiTiler, Stac and Cirrus Private API Gateways

### Changed

- Enforced character limit on cirrus `resource_prefix`

## [2.46.0] - 2025-05-15

### Added

- Added capability to pass a custom S3 bucket for Console UI and Cirrus Dashboard S3 websites

## [2.45.0] - 2025-05-12

### Added

- Added outputs for Console UI and Cirrus Dashboard S3 Bucket names

## [2.44.0] - 2025-05-07

### Fixed

- stac_server: set ENABLE_INGEST_ACTION_TRUNCATE on the ingest lambda rather than the api lambda

## [2.43.0] - 2025-04-30

### Added

- Input to configure stac-server with ENABLE_INGEST_ACTION_TRUNCATE

### Changed

- removing step function permission from `update-state` IAM policy due to change in how
  `update-state` lambda gets errors in cirrus v1.0.0 release

### Fixed

- The variable `enable_collections_authx` defaulted to true, should have defaulted to false.

### Removed

## [2.42.0] - 2025-04-08

### Added

- Added inputs to configure stac-server with stac_id, stac_title, stac_description, and enable_collections_authx

## [2.41.0] - 2025-03-27

### Added

- Added input to allow configuration of stac-server api gateway method authorization type

### Fixed

- Corrected resource string for `update-state` and `process` lambda function
  roles to access `StateDB` indexes.


## [2.40.0] - 2025-03-24

### Added

- Added configuration `stac_server_inputs.opensearch_version`
- Added output for stac-server gateway id

### Changed

- Updated default OpenSearch version to 2.17, from 2.13
- Updated default stac-server version to v3.10.0, from v3.8.0
- Updated default stac-server Lambda runtime to Node 20, from 18

### Fixed

- Corrected resource string for `cirrus` API lambda function role to access
  `StateDB` indexes.

### Removed

- `stac_version` is no longer supported for configuration

## [2.39.0] - 2025-03-21

### Added

- Exposing stac_server_ingest_sns_topic_arn via outputs
- Exposed stac_server_lambda_iam_role_arn via outputs

## [2.38.0] - 2025-03-20

### Added

- Adding capability to change the Stac-Server OpenSearch availability_zone_count via input parameter

## [2.37.0] - 2025-03-20

### Added

- Documentation for the `cirrus` module and its `task-batch-compute`, `task`, and `workflow` submodules
- Direct invocations of the `cirrus` module can now specify a custom resource prefix
- A list of additional security groups can now be added to the VPCes for PRIVATE-type stac-server and/or cirrus API gateways
- Cirrus workflows can now have custom permissions applied to the state machine's execution IAM role
- Cirrus workflows can now invoke any AWS service that provides a state machine integration
- The cirrus `task-batch-compute` submodule now supports parameterization of its definition YAMLs through templating
- The cirrus `workflow` submodule now supports parameterization of its definition YAMLs and state machine JSONs through templating
- The `stac-server` API's `STAC_VERSION` environment variable can now be specified via input variable `stac_version`
- Cirrus deployment parameter store and optional assumable management role intended for the cirrus CLI tool

### Changed

- Renamed all instances of `cirrus_prefix` to `resource_prefix` as a preliminary step for adopting the latter as an input variable across all modules

### Fixed

- Cirrus workflows no longer require at least one cirrus task reference
- Cirrus `pre-batch` and `post-batch` lambdas now work correctly with a payload bucket managed by `cirrus`'s `base` module

### Removed

## [2.36.0] - 2025-03-10

### Changed

- Updated FilmDrop Analytics eks kubernetes version to 1.32 and autoscaler version to 1.32.0

### Removed

- Removed classical WAF support as it is being deprecated by AWS in favor of the newer AWS WAFv2

## [2.35.0] - 2025-03-05

### Removed

- Removed max terraform required version constraints

## [2.34.0] - 2025-02-24

### Fixed

- Fixed incorrect default `cirrus` variables

## [2.33.0] - 2025-02-17

### Fixed

- Fixed occasional planning-time issue with a `data.aws_subnet` block in the `cirrus` and `stac-server` modules

## [2.32.0] - 2025-02-12

### Removed

- Removing monokai from daskhub Dockerfile which was causing the jupyterhub image build to fail

## [2.31.0] - 2025-02-06

### Added

- Custom cirrus lambda dist ZIP can now be used instead of the default
- Custom stac-server lambda dist ZIPs and configuration overrides can now be used for the `api`, `ingest`, and `pre-hook` lambdas
- Support for PRIVATE-type cirrus and stac-server API Gateways
- Ephemeral storage option for cirrus lambda tasks

### Changed

- Inputs to the `cirrus` module's `task-batch-compute`, `task`, and `workflow` submodules are now defined via YAML files instead of HCL object lists
- Cirrus workflow's `template_variables` config is removed in favor of referencing cirrus task output attributes directly

### Fixed

- Fixed the Cirrus `update-state` lambda permissions to allow:
  - Pushing messages to the Cirrus `publish` SNS topic
  - Creating objects in the Cirrus `payload` S3 bucket
- Fixed Cirrus workflow state machine permissions to allow creating state transition events
- Fixed constant state drift caused by multiple `aws_api_gateway_account` resources (one in `stac-server`, one in `cirrus`)

## [2.30.0] - 2024-11-27

### Added

- Final migration of Cirrus IaC to Terraform for compatibility with `cirrus-geo` [v1.0.0a0](https://github.com/cirrus-geo/cirrus-geo/releases) and beyond. The following modules were created to manage all Cirrus Task and Workflow resources through input variables:
  - `modules.cirrus.task_batch_compute`
  - `modules.cirrus.task`
  - `modules.cirrus.workflow`

### Changed

- Moved `modules.cirrus.functions` module to `modules.cirrus.builtin_functions`
- Moved `modules.cirrus.base-builtins` module to `modules.cirrus.base`

## [2.29.0] - 2024-09-27

### Added

- Base Cirrus alarms
- Default FilmDrop Warning and Critical SNS Topics

## [2.28.0] - 2024-09-13

### Added

- Builtin lambdas added to cirrus module along with script to update deployment zip
- API Gateway infrastructure for Cirrus API
- Creation of Cirrus Data and Payload S3 bucket if none is defined via inputs

### Changed

- Consolidated WAF rules into a single one by default for cost savings

## [2.27.0] - 2024-05-31

### Changed

- Rolled back vpc infrastructure changes to support creation of VPC if `deploy_vpc` is set to `true`.

## [2.26.0] - 2024-05-29

### Changed

- Default to stac-server 3.8.0 and OpenSearch 2.13
- For both `stac_server_inputs` and `titiler_inputs`, renamed
  `stac_server_and_titiler_s3_arns` to `authorized_s3_arns`.
- `private_subnets_az_to_id_map` now correctly using ID as the map value instead of previous cidr_block
- `public_subnets_az_to_id_map` now correctly using ID as the map value instead of previous cidr_block

### Added

- titiler-mosaicjson configuration parameter `mosaic_tile_timeout`

### Removed

- VPC and subnets are no longer created by the FD VPC module, since IDs must now be provided
  for preexisting resources.  If `deploy_vpc` was set to `true` on a previous terrform apply,
  then this update will to attempt to delete the VPC and subnets, which will fail due to
  resource dependencies.  The TF state will need to be manually updated to remove these
  references without deleting the underlying AWS resources.

## [2.25.0] - 2024-05-21

### Added

- Added Cirrus terraform base resource set and new cirrus terraform module

### Changed

- `titiler_inputs.mosaic_titiler_release_tag` is now `titiler_inputs.version`
- `cirrus_dashboard_inputs.cirrus_dashboard_release` is now `cirrus_dashboard_inputs.version`
- `console_ui_inputs.filmdrop_ui_release` is now `console_ui_inputs.version`

### Removed

- sample data bucket module has been removed, as it was unused in any projects

## [2.24.0] - 2024-05-20

### Fixed

- Add default values to console-ui inputs to allow tflint validation.

## [2.23.0] - 2024-05-16

### Changed

- Allow 7 instead of 5 characters for `environment`

### Fixed

- Fixed filmdrop built-in vpc output references and mappings

## [2.22.0] - 2024-05-14

### Changed

- Default to filmdrop-ui version v5.3.0
- Default to stac-server v3.7.0

### Added

- Adding support for stac-server API Lambda environment configuration:
  - Access-Control-Allow-Origin: `CORS_ORIGIN`
  - Access-Control-Allow-Credentials: `CORS_CREDENTIALS`
  - Access-Control-Allow-Methods: `CORS_METHODS`
  - Access-Control-Allow-Headers: `CORS_HEADERS`

## [2.21.0] - 2024-05-10

### Changed

- Added consistent naming for CloudFront Basic Auth and other resources.

## [2.20.0] - 2024-05-07

### Added

- Added GitHub Actions workflow to test new commits to main branch and new releases.
- Added GitHub Actions workflow manual trigger to test new commits and PRs.
- Added ci.tfvars with minimal configuration for GitHub Action testing, no CloudFront,
  no Analytics and stac-server with OpenSearch Serverless.

### Changed

- Updated changelog to adhere to spec.
- Updated Terraform AWS Provider minimum version to 5.47.
- Updated CloudFront deployment as optional for FilmDrop UI.
- Updated CloudFront deployment as optional for Cirrus Dashboard.

## [2.19.0] - 2024-04-25

### Changed

- Updated FilmDrop Analytics eks kubernetes version to 1.29 and autoscaler version to 1.29.0.

## [2.18.0] - 2024-04-23

### Added

- Added FilmDrop Analytics cleanup capability.

## [2.17.0] - 2024-04-05

### Changed

- Changed mosaic titiler lambda bucket to generate unique bucket name.
- Changed stac-server security group to generate unique sg name.

## [2.16.0] - 2024-04-02

### Added

- Added VPC support for titiler-mosaicjson.

## [2.15.0] - 2024-04-02

### Changed

- Fixing basic auth CloudFront function.

## [2.14.0] - 2024-03-28

### Changed

- Changed Cirrus Dashboard variables for explicitly requiring inputs for cirrus_api_endpoint and metrics_api_endpoint.

## [2.13.0] - 2024-03-21

### Added

- Adding support for STAC_API_URL env variable for stac-server lambdas.

## [2.12.0] - 2024-03-18

### Added

- Adding support for creating a BasicAuth CloudFront function.

### Fixed

- Fixed input parameters for creating CloudFront functions.

## [2.11.0] - 2024-03-06

### Added

- Adding support for custom origin port for load balancer endpoints.

## [2.10.0] - 2024-03-04

### Changed

- Uses v5.0.0 of the [filmdrop-ui](https://github.com/Element84/filmdrop-ui) by default

## [2.9.0] - 2024-02-29

### Added

- Added flag to deploy stac-server resources, including OpenSearch within or outside
  the vpc, defaults to within vpc.

## [2.8.0] - 2024-02-27

### Changed

- Enabling stac-server post ingest sns publishing

## [2.7.0] - 2024-02-24

### Added

- Added self-managed, managed and fargate node group capability to eks module

## [2.6.0] - 2024-02-20

### Fixed

- Fixed custom domain alias and certificate creation for filmdrop endpoints
- Fixed analytics dask helm installation

## [2.5.0] - 2024-02-12

### Changed

- Update to require version 1.6.x or 1.7.x of Terraform (instead of ~>1.6.6).
- Update to default to stac-server v3.7.0 (from v3.2.0)

## [2.4.0] - 2024-02-11

### Changed

- Update stac-server to use OpenSearch 2.11
- Updated terraform supported version to 1.6.6
- Updating public_subnets_cidr_map name variable name to public_subnets_az_to_id_map
- Updating private_subnets_cidr_map name variable name to private_subnets_az_to_id_map
- Updating analytics load balancer subnets
- Updating analytics ebs csi driver repo

## [2.3.0] - 2023-12-14

### Added

- Added historic and ongoing ingest capability as stac-server submodules

## [2.2.0] - 2023-12-11

### Added

- Added capability for optional CloudFront deployment for stac-server, with a parameter in the stac_server_inputs

## [2.1.0] - 2023-11-29

### Added

- Added OpenSearch Serverless capability to stac-server module

## [2.0.0] - 2023-11-14

### Added

- Added READMEs for titiler and mosaic-titiler linking to unit test instructions and general documentation
- Added flop CLI utility for creating and interacting with FilmDrop test environments
- Added built-in validation of project_name and environment parameters

### Changed

- Adding FilmDrop profiles for deploying components via flags and enabling a 1-step
  deployment via tf-modules repo

### Fixed

- Fixes kubectl version on codebuild for jupyterhub analytics module

## [1.7.0] - 2023-11-13

### Changed

- Default cirrus_dashboard_release_tag to v0.5.1
- Update stac-server to use OpenSearch 2.9

## [1.6.0] - 2023-11-12

### Changed

- The jupyterhub-dask-eks module no longer takes an input `kubernetes_cluster_name`,
  but now requires a parameter `environment`. Resource names that previously used
  `kubernetes_cluster_name` now construct those using the `project_name` and `environment`
  variables
- All jupyterhub-dask-eks and mosaic-titiler module CodeBuild projects are now set with
  a concurrency of 1.
- The jupyterhub-dask-eks module no longer takes inputs
  `filmdrop_analytics_jupyterhub_admin_credentials_secret` or
  `filmdrop_analytics_dask_secret_tokens`, but instead constructs these from the
  `project_name` and `environment` as `${var.project_name}-${var.environment}-admin-credentials`
  and `${var.project_name}-${var.environment}-dask-token`
- jupyterhub-dask-eks CodeBuild project must be manually run, instead of it being run
  automatically in response to a configuration change.
- jupyterhub-dask-eks configuration bucket has been renamed from
  `jupyter-config-${random_id.suffix.hex}` to `fd-${var.project_name}-${var.environment}-jd-cfg-${random_id.suffix.hex}`
- jupyterhub-dask-eks AWS EKS version has been updated to 1.25
- lowercase aws_s3_bucket.jupyter_dask_source_config S3 bucket name
- add .snyk file to ignore rules for public S3 buckets and open auth to API gateway
- The stac-server module renamed numerous resources to use project/stage naming format.
  See README.md for upgrade instructions it you have a preexisting stac-server OpenSearch
  cluster than needs to be preserved upon taking this update.
- Various issues fixed related to stac-server resource name changes
- Removed invalid default values for stac-server variables `vpc_security_group_ids` and `vpc_subnet_ids`

## [1.5.0] - 2023-11-11

### Changed

- fix args being passed to the cloudfront/custom module which were removed in a lint/cleanup commit
- console-ui.filmdrop_ui_release must be gte 4.x, e.g., `v4.0.1`

## [1.4.3] - 2023-11-10

### Changed

- Defining a non-empty `stac_server_s3_bucket_arns` and `titiler_s3_bucket_arns` parameters
  is no longer required. This can now be empty.
- Refined public bucket access policies
- SSM secret creation will now fail if a secret with the same name already exists
- add an optional env var config for mosaic lambda (request_host_header_override)
  that will overridethe host header in the event, so that responses crafted use the
  desired external-facing domain instead of internal API gateway
- set force_delete on daskhub and titiler ECR repos to allow automated destroy
- set force_destroy access logs and logs archive S3 buckets to allow automated destroy

### Removed

- OpenSearch Service linked role is no longer managed by these modules, but instead should
  be created using the bootstrap project.

## [1.4.2] - 2023-09-01

### Changed

- Adding configurable disk_size and capacity_type to eks node groups

## [1.4.1] - 2023-08-29

### Changed

- Add WAF rules to check requests for mosaic titiler - consumer must set "waf_allowed_url"
  to enable (updated to allow OPTIONS)
- Sets element 84 distribution email as maintainer for daskhub dockerfile
- explicitly set bash interpreter for local-exec shell scripts, and don't swallow errors (-e)
- add a trigger for trigger_console_ui_upgrade on config file contents
- add status check to wait for console ui codebuild to complete and return success/failure
- Updated wget TLS to v1.3 (Github began denying the default)
- updated TF resource schemas to work with AWS provider v5

## [1.3.0] - 2023-08-14

### Changed

- Add cloudwatch alarms to mosaic titiler module
- Removes stac ingest policy assignment within the stac server ingest sqs resource
- Utilizes the stac ingest sqs arn to build the correct access policy
- Reverts removal of base_infra/alerts
- Added support jupyterhub deployment as http load balancer if no acm certificates are specified
- Add a variable for stac-server to use the correct root path when cloudfront is used
- For stac-server, OpenSearch 2.7 will be used instead of 2.3.
- truncate S3 cloudfront content_bucket name to 63 characters
- add optional `stac_server_s3_bucket_arns` config input list to stac-server to grant S3 GetObject permissions
- Fix inconsistent plan in jupyterhub trigger by triggering from S3 events
- Try to fix yet another S3 race condition applying versioning/replication config
- Export API gateway ID from mosaic-titiler to fix hard-coded config in top-level TF file

### Fixed

- Fixes jupyterhub race condition for bucket ACLs

## [1.2.1] - 2023-07-29

### Fixed

- Console UI bucket ACL creation now depends on the ownership permission being applied first
- Mosaic TiTitler module now creates directory and checks for wget

## [1.2.0] - 2023-07-27

### Changed

- FilmDrop UI >= 3.0.0 is now required. The configuration file is now
  `./public/config/config.json` instead of `./src/assets/config.js`

## [1.1.4] - 2023-07-25

### Added

- DNS validation capability to allow for cloudfront urls instead of custom aliases
- Adding missing dns_validation input variable on the s3_website module

### Fixed

- Cloudfront default alias

## [1.1.3] - 2023-07-22

### Added

- Adding dns validation capability to allow for cloudfront urls instead of custom aliases

### Fixed

- Multiple deployments now works correctly
- Explicitly sets titiler docker image local exec interpreter
- Fixed EKS permissions and adding SSM Bastion
- Prevent recreation of SSM bastion host
- Adding missing dns_validation input variable on the s3_website module
- Cloudfront default alias

## [1.1.2] - 2023-07-19

### Added

- Partial support for multiple deployments

### Changed

- Many modules now require `project_name` to be defined, including `base_infra/log_archive`,
  `cloudfront/s3_website`, `cloudfront/lb_endpoint`, `cloudfront/apigw_endpoint`, and `stac-server`
- Module `titler` requires `project_name`, `prefix`, and `titiler_stage` variables set
  (may be required from an earlier release)
- Module `jupyterhub-dask-eks` requireds `daskhub_stage` variables set (may be required
  from an earlier release)

### Fixed

- Add dependency of user_init_lambda_zip for the opensearch lambda
- TiTiler bucket ownership Rules
- Pin TiTiler FastAPI version to 0.95 to fix routing issue
- EKS permissions

## [1.1.1] - 2023-05-31

### Added

- Support for FilmDrop UI custom logos

### Fixed

- Bucket permissions

## [1.1.0] - 2023-05-15

### Changed

- Changed Filmdrop UI config from .env to config.js

## [1.0.3] - 2023-04-13

### Added

- EKS module

## [1.0.2] - 2023-03-08

### Changed

Many changes, see commit history

## [1.0.1] - 2023-02-10

### Fixed

- Fixed issue with stac-server opensearch user-init lambda not building except on initial deploy.

## [1.0.0] - 2023-02-09

### Added

- Added support for deploying the stac-server auth key pre-hook lambda. This will deploy
  by default (tbd not having it deploy). Setting `stac_server_auth_pre_hook_enabled` or
  `stac_server_pre_hook_lambda_arn` will cause it not to be used. When enabled, this uses
  an AWS Secrets Manager secret named `stac-server-${stage}-api-auth-keys` to store a JSON
  value that contains a mapping of key (token) values to permission values. Currently, the
  only permission allowed is `write`, which allows read of everything and write if the
  Transaction Extension is enabled.

## [0.0.36] - 2023-01-31

- Start of changelog
