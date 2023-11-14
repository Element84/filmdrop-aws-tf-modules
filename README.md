# FilmDrop Terraform Modules

This repository contains the packaging of FilmDrop terraform modules.

Check out the [changelog](CHANGELOG.md).

## Migration

Document any changes that need to be made by module instances using these modules to uptake
a newer version. For example, if a new required variable is added, this should be documented here.

### 1.next
- Please upgrade to AWS provider v5
- The WAF rules for mosaic titiler have been defined in the mosaic-titler module.  The consumer
  must now pass in an "aws.east" provider because cloudfront requires global resources created in
  us-east-1.  Consumers should set the new "waf_allowed_url" variable to set the WAF rules to enable
  blocking of requests.  Leaving the default of null will set the rules to count only and disable
  blocking.  If the consumer has previous defined a mosaic titiler WAF rule using the "titiler_waf_rules_map"
  variable, this should be removed as it has been replaced with the module's implementation.

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
  - The JavaScript const variables are now JSON attribute names.
  - Parameters (JSON attribute names) are no longer prevised by `VITE_`, e.g.,
    `VITE_DEFAULT_COLLECTION` is now `DEFAULT_COLLECTION`
  - Parameters for which you wish to use the default no longer need to be included as null/empty.
