# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased - TBD

### Added

- Added support for deploying the stac-server auth key pre-hook lambda. This will deploy by default (tbd not having it deploy). Setting `stac_server_auth_pre_hook_enabled` or `stac_server_pre_hook_lambda_arn` will cause it not to be used. When enabled, this uses an AWS Secrets Manager secret named `stac-server-${stage}-api-auth-keys` to store a JSON value that contains a mapping of key (token) values to permission values. Currently, the only permission allowed is `write`, which allows read of everything and write if the Transaction Extension is enabled.

### Fixed

### Changed

### Removed

## v0.0.36 - 2023-Jan-31

- Start of changelog
