## Running unit tests

In order to run unit tests, first install all dependencies in `package.json` using `npm install`.

Then, to run the tests, you can run any of these commands:

`npm test` or `npm run test` runs all tests

`npm run test:unit` runs unit tests in the `tests` directory

`npm run test:coverage` runs unit tests and produces a coverage report

## Steps to manually test live versions of stac-server

The unit tests are contained within the [tests/unit](https://github.com/stac-utils/stac-server/tree/main/tests/unit) folder of the repository. The tests are mainly checking to make sure that the STAC API request is properly structured and returns an appropriate response.

For more information on creating an appropriate STAC API request, please refer to the STAC Server README docs on Github: [STAC API Spec](https://github.com/radiantearth/stac-api-spec/tree/release/v1.0.0) and [STAC Server](https://github.com/stac-utils/stac-server), with particular emphasis on [STAC Item Search](https://github.com/radiantearth/stac-api-spec/tree/release/v1.0.0/item-search).

The stac-server unit tests are not configured to be run against a remote environment, and enabling them to do so is a prohibitive amount of work.
