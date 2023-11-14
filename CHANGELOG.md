# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 1.2.0 2023-07-27

### Changed

- FilmDrop UI >= 3.0.0 is now required. The configuration file is now `./public/config/config.json` instead of `./src/assets/config.js`

## 1.1.4 2023-07-25

## Added

- DNS validation capability to allow for cloudfront urls instead of custom aliases
- Adding missing dns_validation input variable on the s3_website module

## Fixed

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
- Module `titler` requires `project_name`, `prefix`, and `titiler_stage` variables set (may be required from an earlier release)
- Module `jupyterhub-dask-eks` requireds `daskhub_stage` variables set (may be required from an earlier release)

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

- Added support for deploying the stac-server auth key pre-hook lambda. This will deploy by default (tbd not having it deploy). Setting `stac_server_auth_pre_hook_enabled` or `stac_server_pre_hook_lambda_arn` will cause it not to be used. When enabled, this uses an AWS Secrets Manager secret named `stac-server-${stage}-api-auth-keys` to store a JSON value that contains a mapping of key (token) values to permission values. Currently, the only permission allowed is `write`, which allows read of everything and write if the Transaction Extension is enabled.

### Fixed

### Changed

### Removed

## v0.0.36 - 2023-Jan-31

- Start of changelog
