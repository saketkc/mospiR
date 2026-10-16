# mospiR <img src="man/figures/logo.png" align="right" height="139" alt="mospiR logo" />

mospiR is an R client for the [MoSPI Microdata Portal](https://microdata.gov.in).
The package downloads unit-level survey data from the Ministry of Statistics and Programme Implementation (MoSPI) of India.

## Installation

```r
# CRAN
install.packages("mospiR")

# Development version
remotes::install_github("saketkc/mospiR")
```

## Setup

1. Get an API key from [microdata.gov.in](https://microdata.gov.in).
2. Add the key to `~/.Renviron`:

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

# All datasets (all pages)
all <- list_datasets(api_key)

# Datasets with "labour force" in the title
labour <- list_datasets(api_key, query = "labour force")

# Only page 1
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

