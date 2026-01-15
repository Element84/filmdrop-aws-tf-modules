# Migration

Document any changes that need to be made by module instances using these modules to uptake
a newer version. For example, if a new required variable is added, this should be documented here.

### Unreleased


**MOVED: `console-ui` -> `filmdrop-ui`**

- As part of extracting the `console-ui` module it was renamed to the `filmdrop-ui` to bring it in line with the naming conventions of other parts of the FilmDrop ecosystem.  ANY resource that previously used `console-ui` in the name wil be deleted/created anew by the renaming. Handling migration will requiring updating `console-ui` input variables to use the new `filmdrop-ui` naming.

- [stac-server](https://github.com/Element84/terraform-aws-stac-server)
- [filmdrop-ui](https://github.com/Element84/terraform-aws-filmdrop-ui)

**AWS Provider Upgrade v5 -> v6**

The Terraform AWS provider was updated from v5 to v6.

- If calling this module from your own module, update your module's `hashicorp/aws` provider to version constraint to "~> 6.0"

- `terraform init -upgrade`

- If you have cirrus, stac server, or titiler (as *private*) deployed, each has an api gateway for which the Terraform config has been slighty modified due to a few deprecations in the `aws_api_gateway_deployment` resource (see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade#resource-aws_api_gateway_deployment). Your AWS resources should not be modified, this is a change internal to Terraform. To ensure no resources change, perform the following for each of cirrus, stac server, and titiler:

  - Replacing properties denoted in `<>`: `terraform import module.<module_name>.aws_api_gateway_stage.<api_gateway_stage_tf_resource> <rest_api_id>/<stage_name>`

  - As an example: `terraform import --var-file=default.tfvars module.filmdrop.module.stac-server[0].module.stac-server.aws_api_gateway_stage.stac_server_api_gateway_stage b0agq3jmeg/test`

  - You'll see an "Import Successful" notification if your import works as expected

- `terraform apply`

- Important: trigger redeployments of each API Gateway. This is required for the new stages to take effect, without this step your Gateways may be in an inconsistent state.

**Updated the [terraform-aws-stac-server module](https://github.com/Element84/terraform-aws-stac-server) from v1.0.2 to v2.0.0**

- This updates the packaged version of [stac-server](https://github.com/stac-utils/stac-server) from v3.10.0 to v4.5.0.  If you are *not* defining a custom version of stac-server in your tfvars (along with `deploy_local_stac_server_artifacts = true`), the following applies. See the v2.0.0 release notes for full details; the migration steps noted there:

  - The minimum version of OpenSearch that [stac-server](https://github.com/stac-utils/stac-server) v4.5.0 expects is 2.19 (v3.10.0 expected 2.17). Accordingly, projects should update `opensearch_version` to `OpenSearch_2.19` at a minimum.

  - stac-server lambda runtimes should be bumped nodejs20 -> nodejs22

### TODO: - released, need to note which versions

- Removes support for VPC creation. To retain the existing VPC resources, manually
  remove them from the Terraform state file. However, you should then create another
  IaC deployment for that VPC.
- `stac_server_inputs` and `titiler_inputs`, renamed
  `stac_server_and_titiler_s3_arns` to `authorized_s3_arns`.
- `titiler_inputs.mosaic_titiler_release_tag` is now `titiler_inputs.version`
- `cirrus_dashboard_inputs.cirrus_dashboard_release` is now `cirrus_dashboard_inputs.version`
- `console_ui_inputs.filmdrop_ui_release` is now `console_ui_inputs.version`
- `deploy_sample_data_bucket` option has been removed

### 2.56.0

- If using the optional `cirrus_inputs.lambda_version` or `cirrus_inputs.lambda_zip_filepath` to denote a specific version of Cirrus, you must additionally define a `cirrus_inputs.lambda_pyversion`. Cirrus geo versions are now tied to specific Python runtime versions; see the [cirrus-geo releases](https://github.com/cirrus-geo/cirrus-geo/releases) for details.

- Updated Terraform version to latest stable 1.13.4. While not technically a semver breaking change, you may want to review the [Terraform upgrade guides](https://developer.hashicorp.com/terraform/language/v1.8.x/upgrade-guides) for 1.8, 1.9, 1.10, 1.11, 1.12, and 1.13

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
