# List datasets from the MoSPI Microdata Portal

List datasets from the MoSPI Microdata Portal

## Usage

``` r
list_datasets(api_key, page = NULL, query = NULL)
```

## Arguments

- api_key:

  MoSPI API key.

- page:

  Page number to fetch. \`NULL\` (default) fetches all pages.

- query:

  Title filter; case-insensitive substring match, applied client-side.

## Value

Data frame with columns \`id\`, \`idno\`, \`title\`, etc. \`NULL\` on
failure.

## Examples

``` r
if (FALSE) { # \dontrun{
datasets <- list_datasets("your-api-key")
labour <- list_datasets("your-api-key", query = "labour force")
page1 <- list_datasets("your-api-key", page = 1)
} # }
```
