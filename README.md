# FilmDrop Terraform Modules

This repository contains the packaging of FilmDrop terraform modules.

Check out the [changelog](CHANGELOG.md).

## Migration

Document any changes that need to be made by module instances using these modules to uptake
a newer version. For example, if a new required variable is added, this should be documented here.

### 1.2.0

- FilmDrop UI version >= 3.0.0 is now required. Previously, the configuration file was a 
  JavaScript file and was placed in `./src/assets/config.js`. It is now a JSON file and is placed in `./public/config/config.json`. This change can be seen in [this commit](https://github.com/Element84/filmdrop-ui/pull/202/files#diff-06572a96a58dc510037d5efa622f9bec8519bc1beab13c9f251e97e657a9d4ed). The primary changes are:
  - The JavaScript const variables are now JSON attribute names.
  - Parameters (JSON attribute names) are no longer prevised by `VITE_`, e.g., `VITE_DEFAULT_COLLECTION` is now `DEFAULT_COLLECTION`
  - Parameters for which you wish to use the default no longer need to be included as null/empty.
