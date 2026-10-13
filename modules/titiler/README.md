# Filmdrop-Titiler

## Documentation

Detailed Filmdrop-Titiler documenation on this lightweight implementation can be found [here](https://github.com/Element84/filmdrop-titiler/blob/main/README.md) and is maintained by Element 84.

## Mosaic

Set `mosaic_enabled = true` to deploy with the filmdrop-titiler mosaic routes (`/mosaicjson/mosaics`). This creates a DynamoDB table, grants the Lambda access to it, and sets `TITILER_API_MOSAIC_BACKEND` and `TITILER_API_MOSAIC_HOST`. The selected `titiler_release_tag` must include the mosaic extension.
