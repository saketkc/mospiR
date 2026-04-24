BASE_URL <- "https://microdata.gov.in/NADA/index.php/api"
MAX_RETRIES <- 4
RETRY_DELAY <- 3

#' @importFrom httr2 request req_headers req_url_query req_perform resp_body_json resp_body_raw req_retry resp_status
NULL

.request_with_retry <- function(url, api_key, query = list()) {
  req <- request(url) |>
    req_headers("X-API-KEY" = api_key) |>
    req_retry(
      max_tries = MAX_RETRIES,
      retry_on_failure = FALSE,
      is_transient = function(resp) resp_status(resp) %in% c(401, 429, 500, 502, 503, 504),
      backoff = function(attempt) RETRY_DELAY * attempt
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
      message("Error fetching dataset list: ", conditionMessage(e))
      NULL
    }
  )
}

.download_one_file <- function(dataset_id, file_name, b64, folder_path, api_key) {
  url <- paste0(BASE_URL, "/fileslist/download/", dataset_id, "/", b64)
  tryCatch(
    {
      resp <- .request_with_retry(url, api_key)
      file_path <- file.path(folder_path, file_name)
      writeBin(resp_body_raw(resp), file_path)
      message("Downloaded: ", file_path)
      file_path
    },
    error = function(e) {
      message("Error downloading '", file_name, "': ", conditionMessage(e))
      NULL
    }
  )
}

#' List datasets from the MoSPI Microdata Portal
#'
#' @param api_key MoSPI API key.
#' @param page Page number to fetch. `NULL` (default) fetches all pages.
#' @param query Title filter; case-insensitive substring match, applied client-side.
#'
#' @return Data frame with columns `id`, `idno`, `title`, etc. `NULL` on failure.
#' @export
#'
#' @examples
#' \dontrun{
#' datasets <- list_datasets("your-api-key")
#' labour <- list_datasets("your-api-key", query = "labour force")
#' page1 <- list_datasets("your-api-key", page = 1)
#' }
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
#' @param dataset_id Dataset `idno` (e.g., `"DDI-IND-NSO-ASI-2020-21"`).
#' @param api_key MoSPI API key.
#'
#' @return Data frame with columns `name`, `base64`, `size`, etc. `NULL` on failure.
#' @export
#'
#' @examples
#' \dontrun{
#' files <- list_files("DDI-IND-NSO-ASI-2020-21", "your-api-key")
#' }
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
      message("Error fetching file list for '", dataset_id, "': ", conditionMessage(e))
      NULL
    }
  )
}

#' Download a single file from a dataset
#'
#' @param dataset_id Dataset `idno`.
#' @param file_name File name as returned by [list_files()].
#' @param folder_path Destination directory; created if missing.
#' @param api_key MoSPI API key.
#'
#' @return Path to the saved file (invisibly). `NULL` on failure.
#' @export
#'
#' @examples
#' \dontrun{
#' path <- download_file("DDI-IND-NSO-ASI-2020-21", "ASI_DATA.zip", "./data", "your-api-key")
#' }
download_file <- function(dataset_id, file_name, folder_path, api_key) {
  dir.create(folder_path, showWarnings = FALSE, recursive = TRUE)

  files <- list_files(dataset_id, api_key)
  if (is.null(files)) {
    message("Failed to retrieve file list.")
    return(invisible(NULL))
  }

  idx <- which(files$name == file_name)
  if (length(idx) == 0) {
    message("File '", file_name, "' not found in dataset '", dataset_id, "'.")
    message("Available files: ", paste(files$name, collapse = ", "))
    return(invisible(NULL))
  }

  invisible(.download_one_file(dataset_id, file_name, files$base64[idx[1]], folder_path, api_key))
}

#' Download all files for a dataset
#'
#' @param dataset_id Dataset `idno`.
#' @param folder_path Destination directory; created if missing.
#' @param api_key MoSPI API key.
#'
#' @return Character vector of saved file paths (invisibly).
#' @export
#'
#' @examples
#' \dontrun{
#' paths <- download_dataset("DDI-IND-NSO-ASI-2020-21", "./data", "your-api-key")
#' }
download_dataset <- function(dataset_id, folder_path, api_key) {
  dir.create(folder_path, showWarnings = FALSE, recursive = TRUE)

  files <- list_files(dataset_id, api_key)
  if (is.null(files)) {
    message("Failed to retrieve file list.")
    return(invisible(character(0)))
  }
  if (nrow(files) == 0) {
    message("No files found for dataset '", dataset_id, "'.")
    return(invisible(character(0)))
  }

  results <- lapply(seq_len(nrow(files)), function(i) {
    .download_one_file(dataset_id, files$name[i], files$base64[i], folder_path, api_key)
  })

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
