#' Extract a downloaded archive
#'
#' Extracts a `.zip`, `.rar`, `.7z` or `.tar` file from the portal.
#' The function uses the archive package first. If the archive package is
#' not installed or cannot extract the file, the function uses the command
#' line tool `unar`.
#'
#' On Linux, the archive package uses the libarchive of the system.
#' libarchive versions before 3.7.4 (for example 3.7.2 in Ubuntu 24.04) give
#' a "File CRC error" on some `.rar` files from the portal. To extract these
#' files, install `unar` (`sudo apt-get install unar` on Ubuntu,
#' `brew install unar` on macOS).
#'
#' The function extracts into a temporary directory and then moves the files
#' into `dir`. Thus, if the extraction fails, `dir` does not change, and the
#' function does not make `dir`.
#' Files in `dir` that have the same names as files in the archive are
#' replaced.
#'
#' @param path Path of the archive file.
#' @param dir Destination directory. The function makes the directory if it
#'   does not exist.
#'
#' @return A character vector of the paths of the extracted files, as an
#'   invisible value. `NULL` if the extraction is not successful.
#' @export
#'
#' @examplesIf requireNamespace("archive", quietly = TRUE)
#' src <- file.path(tempdir(), "example.txt")
#' writeLines("example", src)
#' zip_file <- file.path(tempdir(), "example.zip")
#' archive::archive_write_files(zip_file, src)
#' extract_archive(zip_file, file.path(tempdir(), "extracted"))
extract_archive <- function(path, dir) {
  if (!file.exists(path)) {
    message("Cannot extract '", path, "': the file does not exist")
    return(invisible(NULL))
  }
  parent <- dirname(dir)
  dir.create(parent, showWarnings = FALSE, recursive = TRUE)
  # stage next to dir; file.rename fails across file systems
  staging <- tempfile("extract-", tmpdir = normalizePath(parent))
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)

  ok <- .extract_with_archive(path, staging) || {
    unlink(staging, recursive = TRUE)
    .extract_with_unar(path, staging)
  }
  if (!ok) {
    hint <- if (!nzchar(Sys.which("unar"))) ". Install the command line tool unar."
    message("Cannot extract '", path, "'", hint)
    return(invisible(NULL))
  }

  extracted <- list.files(staging, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  # one rename is all or nothing, so a failure never leaves a partial dir
  if (!dir.exists(dir)) {
    if (!file.rename(staging, dir)) {
      message("Cannot move the extracted files into '", dir, "'")
      return(invisible(NULL))
    }
    return(invisible(file.path(dir, extracted)))
  }
  for (entry in list.files(staging, all.files = TRUE, no.. = TRUE)) {
    target <- file.path(dir, entry)
    unlink(target, recursive = TRUE)
    if (!file.rename(file.path(staging, entry), target)) {
      message("Cannot move '", entry, "' into '", dir, "'")
      return(invisible(NULL))
    }
  }
  invisible(file.path(dir, extracted))
}

.extract_with_archive <- function(path, dir) {
  if (!requireNamespace("archive", quietly = TRUE)) {
    return(FALSE)
  }
  tryCatch(
    {
      archive::archive_extract(path, dir = dir)
      TRUE
    },
    error = function(e) {
      message("archive_extract() cannot extract '", path, "': ", conditionMessage(e))
      FALSE
    }
  )
}

.extract_with_unar <- function(path, dir) {
  if (!nzchar(Sys.which("unar"))) {
    return(FALSE)
  }
  message("Using unar to extract '", path, "'")
  # -D: no wrapper directory, matches archive_extract
  out <- suppressWarnings(system2("unar", c("-q", "-f", "-D", "-o", shQuote(dir), shQuote(path)),
    stdout = TRUE, stderr = TRUE
  ))
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    message("unar cannot extract '", path, "': ", paste(out, collapse = " "))
    return(FALSE)
  }
  TRUE
}
