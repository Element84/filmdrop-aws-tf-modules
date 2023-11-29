# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

## 2.1.0

### Added
- Added OpenSearch Serverless capability to stac-server module

## 2.0.0

### Added

- Added READMEs for titiler and mosaic-titiler linking to unit test instructions and general documentation
- Added flop CLI utility for creating and interacting with FilmDrop test environments
- Added built-in validation of project_name and environment parameters

### Changed

- Adding FilmDrop profiles for deploying components via flags and enabling a 1-step deployment via tf-modules repo

### Fixed

- Fixes kubectl version on codebuild for jupyterhub analytics module

## 1.7.0

### Changed

- Default cirrus_dashboard_release to v0.5.1
- Update stac-server to use OpenSearch 2.9

## 1.6.0

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

## 1.5.0

### Changed

- fix args being passed to the cloudfront/custom module which were removed in a lint/cleanup commit
- console-ui.filmdrop_ui_release must be gte 4.x, e.g., `v4.0.1`

## 1.4.3

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

## 1.4.2 2023-09-01

### Changed

- Adding configurable disk_size and capacity_type to eks node groups

## 1.4.1 2023-08-29

### Changed

- Add WAF rules to check requests for mosaic titiler - consumer must set "waf_allowed_url"
  to enable (updated to allow OPTIONS)
- Sets element 84 distribution email as maintainer for daskhub dockerfile
- explicitly set bash interpreter for local-exec shell scripts, and don't swallow errors (-e)
- add a trigger for trigger_console_ui_upgrade on config file contents
- add status check to wait for console ui codebuild to complete and return success/failure
- Updated wget TLS to v1.3 (Github began denying the default)
- updated TF resource schemas to work with AWS provider v5

## 1.3.0 2023-08-14

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

## 1.2.1 2023-07-29

### Fixed

- Console UI bucket ACL creation now depends on the ownership permission being applied first
- Mosaic TiTitler module now creates directory and checks for wget

## 1.2.0 2023-07-27

### Changed

- FilmDrop UI >= 3.0.0 is now required. The configuration file is now
  `./public/config/config.json` instead of `./src/assets/config.js`

## 1.1.4 2023-07-25

### Added

- DNS validation capability to allow for cloudfront urls instead of custom aliases
- Adding missing dns_validation input variable on the s3_website module

### Fixed

- Cloudfront default alias

## 1.1.3 2023-07-22

### Added

- Adding dns validation capability to allow for cloudfront urls instead of custom aliases

### Fixed

- Multiple deployments now works correctly
- Explicitly sets titiler docker image local exec interpreter
- Fixed EKS permissions and adding SSM Bastion
- Prevent recreation of SSM bastion host
- Adding missing dns_validation input variable on the s3_website module
- Cloudfront default alias

## 1.1.2 2023-07-19

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

## 1.1.1 - 2023-05-31

### Added

- Support for FilmDrop UI custom logos

### Fixed

- Bucket permissions

## 1.1.0 - 2023-05-15

### Changed

- Changed Filmdrop UI config from .env to config.js

## 1.0.3 - 2023-04-13

### Added

- EKS module

## 1.0.2 - 2023-03-08

Many changes, see commit history

## 1.0.1 - 2023-02-10

### Fixed

- Fixed issue with stac-server opensearch user-init lambda not building except on initial deploy.

## 1.0.0 - 2023-02-09

### Added

- Added support for deploying the stac-server auth key pre-hook lambda. This will deploy
  by default (tbd not having it deploy). Setting `stac_server_auth_pre_hook_enabled` or
  `stac_server_pre_hook_lambda_arn` will cause it not to be used. When enabled, this uses
  an AWS Secrets Manager secret named `stac-server-${stage}-api-auth-keys` to store a JSON
  value that contains a mapping of key (token) values to permission values. Currently, the
  only permission allowed is `write`, which allows read of everything and write if the
  Transaction Extension is enabled.

### Fixed

### Changed

### Removed

## v0.0.36 - 2023-Jan-31

- Start of changelog
