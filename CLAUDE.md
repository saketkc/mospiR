# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Commands

``` r
# Build documentation (roxygen2 → man/ and NAMESPACE)
devtools::document()

# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-mospiR.R")

# Full R CMD check
devtools::check()

# Build vignettes
devtools::build_vignettes()

# Install locally
devtools::install()
```

## Architecture

`mospiR` is a minimal R package (single source file) wrapping the [MoSPI
NADA API](https://microdata.gov.in/NADA/index.php/api).

**All logic lives in `R/mospiR.R`:**

- Public functions:
  [`list_datasets()`](https://saketkc.github.io/mospiR/reference/list_datasets.md),
  [`list_files()`](https://saketkc.github.io/mospiR/reference/list_files.md),
  [`download_file()`](https://saketkc.github.io/mospiR/reference/download_file.md),
  [`download_dataset()`](https://saketkc.github.io/mospiR/reference/download_dataset.md)
- Private helpers (`.`-prefixed): `.request_with_retry()`,
  `.fetch_page()`, `.download_one_file()`, `.rows_to_df()`

**Request layer:** Every outbound call goes through
`.request_with_retry()`, which uses `httr2`’s `req_retry()` with up to 4
attempts and exponential backoff on 401/429/5xx.

**Pagination:**
[`list_datasets()`](https://saketkc.github.io/mospiR/reference/list_datasets.md)
with `page = NULL` auto-paginates by reading `result$total` and
`result$limit` from the first response, then sequentially fetching
remaining pages. Title filtering (`query`) is client-side after all
pages are collected.

**Downloads:**
[`download_file()`](https://saketkc.github.io/mospiR/reference/download_file.md)
first calls
[`list_files()`](https://saketkc.github.io/mospiR/reference/list_files.md)
to resolve the file’s `base64` token, then passes it to
`.download_one_file()`.
[`download_dataset()`](https://saketkc.github.io/mospiR/reference/download_dataset.md)
iterates all rows returned by
[`list_files()`](https://saketkc.github.io/mospiR/reference/list_files.md).

**Data normalisation:** `.rows_to_df()` converts a list-of-lists (API
JSON arrays) into a `data.frame`, filling missing keys with `NA`. This
is the only helper covered by tests.

## API key

The API key is expected in the `MOSPI_KEY` environment variable
(typically set in `~/.Renviron`). It is passed as the `X-API-KEY`
header.

## Data in the repo

`data/hces/` contains downloaded HCES survey archives (`.rar` / Nesstar
format). These are large binary files, not R source. The vignette
`vignettes/hces-to-csv.Rmd` documents how to work with them using the
companion [`nesstarR`](https://github.com/nso-india/nesstarR) package.
