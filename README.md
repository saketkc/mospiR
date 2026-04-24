# mospiR

An R client for the [MoSPI Microdata Portal](https://microdata.gov.in). Downloads unit-level survey data published by India's Ministry of Statistics and Programme Implementation.

## Installation

```r
remotes::install_github("saketkc/mospiR")
```

## Setup

Get an API key from [microdata.gov.in](https://microdata.gov.in), then add it to `~/.Renviron`:

```r
MOSPI_KEY=your-key-here
```

```r
api_key <- Sys.getenv("MOSPI_KEY")
```

## Usage

### Search datasets

```r
library(mospiR)

# All datasets (fetches all pages)
all <- list_datasets(api_key)

# Filter by keyword
labour <- list_datasets(api_key, query = "labour force")

# Single page
page1 <- list_datasets(api_key, page = 1)
```

### List files in a dataset

```r
files <- list_files("DDI-IND-MOSPI-NSSO-68Rnd-Sch2.0-July2011-June2012", api_key)
files[, c("name", "size")]
```

### Download a single file

```r
download_file(
  dataset_id  = "DDI-IND-MOSPI-NSSO-68Rnd-Sch2.0-July2011-June2012",
  file_name   = "Nss68_1.0_Type2_new format.rar",
  folder_path = "data/nss68",
  api_key     = api_key
)
```

### Download all files in a dataset

```r
download_dataset(
  dataset_id  = "DDI-IND-MOSPI-NSSO-68Rnd-Sch2.0-July2011-June2012",
  folder_path = "data/nss68",
  api_key     = api_key
)
```

## Functions

| Function | Description |
|---|---|
| `list_datasets(api_key, page, query)` | List datasets; `page = NULL` fetches all pages; `query` filters by title (client-side) |
| `list_files(dataset_id, api_key)` | Files in a dataset (`name`, `base64`, `size`, …) |
| `download_file(dataset_id, file_name, folder_path, api_key)` | Download one file by name |
| `download_dataset(dataset_id, folder_path, api_key)` | Download all files in a dataset |

Failed requests retry up to 4 times with exponential backoff on 401, 429, and 5xx.

