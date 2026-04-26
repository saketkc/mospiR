# Download a single file from a dataset

Download a single file from a dataset

## Usage

``` r
download_file(dataset_id, file_name, folder_path, api_key)
```

## Arguments

- dataset_id:

  Dataset \`idno\`.

- file_name:

  File name as returned by \[list_files()\].

- folder_path:

  Destination directory; created if it does not exist.

- api_key:

  MoSPI API key.

## Value

Path to the saved file (invisibly). \`NULL\` on failure.

## Examples

``` r
if (FALSE) { # \dontrun{
path <- download_file("DDI-IND-NSO-ASI-2020-21", "ASI_DATA.zip", "./data", "your-api-key")
} # }
```
