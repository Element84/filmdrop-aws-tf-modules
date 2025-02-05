# Purpose

This is a simple utility module created to facilitate storing Cirrus `task`,
`task-batch-compute`, and `workflow` input configurations as individual YAML
files rather than lists of HCL objects in each environment configuration.

The object schema used by each of these modules is complex, and as such,
Terraform is unable to automatically convert each tuple of disparate HCL objects
derived from YAML into a list of typed objects. This leads to a number of
type-related problems when the `cirrus` module has a variable number of `task`,
`task-batch-compute`, and `workflow` submodule invocations.

Those submodules operate on just one HCL configuration object at a time, so each
tuple must be converted _after_ the `cirrus` module has read the YAML files into
tuples but _before_ each submodule is called. Thus, this module was created to
sit between the two and perform explicit typecasting on each tuple in order to
produce a list of typed objects. It does this by simply using `variable` blocks
with strict object types that are immediately passed to `output` blocks. No
additional logic or resource creation is necessary.
