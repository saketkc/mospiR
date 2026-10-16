BASE_URL <- "https://microdata.gov.in/NADA/index.php/api"
MAX_RETRIES <- 6
RETRY_DELAY <- 2

#' @importFrom httr2 request req_headers req_url_query req_perform resp_body_json resp_body_raw req_retry resp_status req_throttle
NULL

.request_with_retry <- function(url, api_key, query = list()) {
  req <- request(url) |>
    req_headers("X-API-KEY" = api_key) |>
    req_throttle(rate = 10 / 60) |>
    req_retry(
      max_tries = MAX_RETRIES,
      retry_on_failure = FALSE,
      is_transient = function(resp) resp_status(resp) %in% c(401, 429, 500, 502, 503, 504),
      backoff = function(attempt) RETRY_DELAY * (2^(attempt - 1))
    )

  if (length(query) > 0) {
    req <- do.call(req_url_query, c(list(req), query))
  }

  req_perform(req)
}

.fetch_page <- function(api_key, page) {
  tryCatch(
    {
      resp <- .request_with_retry(
        paste0(BASE_URL, "/listdatasets"),
        api_key,
        query = list(page = page)
      )
      resp_body_json(resp)
    },
    error = function(e) {
      message("Cannot get the dataset list: ", conditionMessage(e))
      NULL
    }
  )
}

.download_one_file <- function(dataset_id, file_name, b64, folder_path, api_key,
                               expected_size = NULL) {
  url <- paste0(BASE_URL, "/fileslist/download/", dataset_id, "/", b64)
  file_path <- file.path(folder_path, file_name)
  tryCatch(
    {
      resp <- .request_with_retry(url, api_key)
      body <- resp_body_raw(resp)

      if (length(body) == 0) {
        message("Cannot download '", file_name, "': the response body is empty")
        return(NULL)
      }

      writeBin(body, file_path)

      if (!file.exists(file_path) || file.size(file_path) == 0) {
        if (file.exists(file_path)) file.remove(file_path)
        message("Cannot download '", file_name, "': the file is empty after the write")
        return(NULL)
      }

      if (!is.null(expected_size)) {
        actual <- file.size(file_path)
        expected_bytes <- .parse_size_string(expected_size)
        if (!is.na(expected_bytes) && actual < expected_bytes * 0.9) {
          message(
            "Warning: the size of '", file_name, "' is not correct: ",
            "expected approximately ", expected_size, ", received ",
            format(actual, big.mark = ","), " bytes"
          )
        }
      }

      message(
        "Downloaded: ", file_path,
        " (", format(file.size(file_path), big.mark = ","), " bytes)"
      )
      file_path
    },
    error = function(e) {
      if (file.exists(file_path) && file.size(file_path) == 0) {
        file.remove(file_path)
      }
      message("Cannot download '", file_name, "': ", conditionMessage(e))
      NULL
    }
  )
}

#' Convert a size text (for example, "116.95 MB") to bytes
#' @noRd
.parse_size_string <- function(size_str) {
  if (is.null(size_str) || is.na(size_str) || !nzchar(size_str)) {
    return(NA_real_)
  }
  size_str <- trimws(size_str)
  m <- regmatches(size_str, regexec("^([0-9.]+)\\s*(KB|MB|GB|B)$", size_str, ignore.case = TRUE))[[1]]
  if (length(m) < 3) {
    return(NA_real_)
  }
  num <- as.numeric(m[2])
  unit <- toupper(m[3])
  multiplier <- switch(unit,
    "B" = 1,
    "KB" = 1024,
    "MB" = 1024^2,
    "GB" = 1024^3,
    1
  )
  num * multiplier
}

#' List datasets from the MoSPI Microdata Portal
#'
#' @param api_key MoSPI API key.
#' @param page Page number to get. If `NULL` (default), the function gets all
#'   the pages.
#' @param query Text to find in the dataset titles. Upper case and lower case
#'   letters are equal. The comparison occurs on your computer.
#'
#' @return A data frame with the columns `id`, `idno`, `title`, and other
#'   columns. `NULL` if the request is not successful.
#' @export
#'
#' @examplesIf nzchar(Sys.getenv("MOSPI_KEY"))
#' page1 <- list_datasets(Sys.getenv("MOSPI_KEY"), page = 1)
#' head(page1[, c("idno", "title")])
list_datasets <- function(api_key, page = NULL, query = NULL) {
  if (!is.null(page)) {
    data <- .fetch_page(api_key, page)
    if (is.null(data)) {
      return(NULL)
    }
    rows <- data$result$rows
  } else {
    first_page <- .fetch_page(api_key, 1)
    if (is.null(first_page)) {
      return(NULL)
    }

    result <- first_page$result
    rows <- result$rows
    total <- as.integer(result$total)
    limit <- as.integer(result$limit)
    pages <- ceiling(total / limit)

    for (p in seq_len(pages)[-1]) {
      data <- .fetch_page(api_key, p)
      if (is.null(data)) break
      rows <- c(rows, data$result$rows)
    }
  }

  if (!is.null(query)) {
    query_lower <- tolower(query)
    rows <- rows[vapply(rows, function(d) {
      grepl(query_lower, tolower(if (is.null(d$title)) "" else d$title), fixed = TRUE)
    }, logical(1))]
  }

  if (length(rows) == 0) {
    return(data.frame())
  }
  .rows_to_df(rows)
}

#' List files available for a dataset
#'
#' @param dataset_id Dataset `idno`, for example `"DDI-IND-NSO-ASI-2020-21"`.
#' @param api_key MoSPI API key.
#'
#' @return A data frame with the columns `name`, `base64`, `size`, and other
#'   columns. `NULL` if the request is not successful.
#' @export
#'
#' @examplesIf nzchar(Sys.getenv("MOSPI_KEY"))
#' files <- list_files("DDI-IND-NSO-ASI-2020-21", Sys.getenv("MOSPI_KEY"))
list_files <- function(dataset_id, api_key) {
  url <- paste0(BASE_URL, "/datasets/", dataset_id, "/fileslist")
  tryCatch(
    {
      resp <- .request_with_retry(url, api_key)
      data <- resp_body_json(resp)
      files <- data$files
      if (length(files) == 0) {
        return(data.frame())
      }
      .rows_to_df(files)
    },
    error = function(e) {
      message("Cannot get the file list for '", dataset_id, "': ", conditionMessage(e))
      NULL
    }
  )
}

#' Download a single file from a dataset
#'
#' @param dataset_id Dataset `idno`.
#' @param file_name File name from the `name` column of [list_files()].
#' @param folder_path Destination directory. The function makes the directory
#'   if it does not exist.
#' @param api_key MoSPI API key.
#' @param .files_cache A file list from [list_files()]. If `NULL` (default),
#'   the function gets the file list from the portal. Use this argument when
#'   you download many files from one dataset. This prevents more API requests.
#'
#' @return The path of the saved file, as an invisible value. `NULL` if the
#'   download is not successful.
#' @export
#'
#' @examplesIf nzchar(Sys.getenv("MOSPI_KEY"))
#' path <- download_file(
#'   "DDI-IND-NSO-ASI-2020-21", "DDI-IND-NSO-ASI-2020-21.xml",
#'   tempdir(), Sys.getenv("MOSPI_KEY")
#' )
download_file <- function(dataset_id, file_name, folder_path, api_key, .files_cache = NULL) {
  dir.create(folder_path, showWarnings = FALSE, recursive = TRUE)

  files <- .files_cache
  if (is.null(files)) {
    files <- list_files(dataset_id, api_key)
  }
  if (is.null(files)) {
    message("Cannot get the file list.")
    return(invisible(NULL))
  }

  idx <- which(files$name == file_name)
  if (length(idx) == 0) {
    message("File '", file_name, "' is not in dataset '", dataset_id, "'.")
    message("Available files: ", paste(files$name, collapse = ", "))
    return(invisible(NULL))
  }

  expected <- if ("size" %in% names(files)) files$size[idx[1]] else NULL
  invisible(.download_one_file(dataset_id, file_name, files$base64[idx[1]], folder_path, api_key,
    expected_size = expected
  ))
}

#' Download all files for a dataset
#'
#' @param dataset_id Dataset `idno`.
#' @param folder_path Destination directory. The function makes the directory
#'   if it does not exist.
#' @param api_key MoSPI API key.
#' @param overwrite If `FALSE` (default), the function does not download the
#'   files that are already in `folder_path`.
#'
#' @return A character vector of the paths of the saved files, as an
#'   invisible value.
#' @export
#'
#' @examplesIf nzchar(Sys.getenv("MOSPI_KEY"))
#' \donttest{
#' # This dataset is approximately 270 MB.
#' paths <- download_dataset(
#'   "DDI-IND-NSO-ASI-2020-21", tempdir(), Sys.getenv("MOSPI_KEY")
#' )
#' }
download_dataset <- function(dataset_id, folder_path, api_key, overwrite = FALSE) {
  dir.create(folder_path, showWarnings = FALSE, recursive = TRUE)

  files <- list_files(dataset_id, api_key)
  if (is.null(files)) {
    message("Cannot get the file list.")
    return(invisible(character(0)))
  }
  if (nrow(files) == 0) {
    message("Dataset '", dataset_id, "' has no files.")
    return(invisible(character(0)))
  }

  message("Dataset '", dataset_id, "': ", nrow(files), " files to download")

  results <- vector("list", nrow(files))
  for (i in seq_len(nrow(files))) {
    dest <- file.path(folder_path, files$name[i])
    if (!overwrite && file.exists(dest)) {
      message("  [", i, "/", nrow(files), "] SKIP (exists): ", files$name[i])
      results[[i]] <- dest
      next
    }
    expected <- if ("size" %in% names(files)) files$size[i] else NULL
    results[[i]] <- .download_one_file(
      dataset_id, files$name[i], files$base64[i], folder_path, api_key,
      expected_size = expected
    )
  }

  invisible(Filter(Negate(is.null), unlist(results)))
}

.rows_to_df <- function(rows) {
  keys <- unique(unlist(lapply(rows, names)))
  out <- lapply(keys, function(k) {
    vals <- lapply(rows, function(r) {
      v <- r[[k]]
      if (is.null(v)) NA else v
    })
    if (all(lengths(vals) <= 1)) unlist(vals) else vals
  })
  names(out) <- keys
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}
