# List files available for a dataset

List files available for a dataset

## Usage

``` r
list_files(dataset_id, api_key)
```

## Arguments

- dataset_id:

  Dataset \`idno\` (e.g., \`"DDI-IND-NSO-ASI-2020-21"\`).

- api_key:

  MoSPI API key.

## Value

Data frame with columns \`name\`, \`base64\`, \`size\`, etc. \`NULL\` on
failure.

## Examples

``` r
if (FALSE) { # \dontrun{
files <- list_files("DDI-IND-NSO-ASI-2020-21", "your-api-key")
} # }
```
