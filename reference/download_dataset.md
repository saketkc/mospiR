# Download all files for a dataset

Download all files for a dataset

## Usage

``` r
download_dataset(dataset_id, folder_path, api_key)
```

## Arguments

- dataset_id:

  Dataset \`idno\`.

- folder_path:

  Destination directory; created if it does not exist.

- api_key:

  MoSPI API key.

## Value

Character vector of saved file paths (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
paths <- download_dataset("DDI-IND-NSO-ASI-2020-21", "./data", "your-api-key")
} # }
```
