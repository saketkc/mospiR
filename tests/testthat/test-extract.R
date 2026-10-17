new_dir <- function() {
  d <- tempfile("test-")
  dir.create(d)
  d
}

make_zip <- function() {
  src <- new_dir()
  dir.create(file.path(src, "sub"))
  writeLines("one", file.path(src, "one.txt"))
  writeLines("two", file.path(src, "sub", "two.txt"))
  zip_file <- tempfile(fileext = ".zip")
  archive::archive_write_dir(zip_file, src)
  zip_file
}

test_that("extract_archive extracts with the archive package", {
  skip_if_not_installed("archive")
  dir <- file.path(new_dir(), "out")
  out <- extract_archive(make_zip(), dir)
  expect_setequal(out, file.path(dir, c("one.txt", "sub/two.txt")))
  expect_equal(readLines(file.path(dir, "sub", "two.txt")), "two")
})

test_that("extract_archive keeps other files in dir and returns only the new ones", {
  skip_if_not_installed("archive")
  dir <- new_dir()
  writeLines("keep", file.path(dir, "keep.txt"))
  out <- extract_archive(make_zip(), dir)
  expect_false(file.path(dir, "keep.txt") %in% out)
  expect_true(file.exists(file.path(dir, "keep.txt")))
  # a second extraction replaces the files
  expect_length(extract_archive(make_zip(), dir), 2)
})

test_that("extract_archive uses unar when archive_extract() fails", {
  skip_if_not_installed("archive")
  skip_if(!nzchar(Sys.which("unar")), "unar is not installed")
  zip_file <- make_zip()
  local_mocked_bindings(.extract_with_archive = function(path, dir) FALSE)
  dir <- file.path(new_dir(), "out")
  expect_message(out <- extract_archive(zip_file, dir), "unar")
  expect_setequal(out, file.path(dir, c("one.txt", "sub/two.txt")))
})

test_that("extract_archive returns NULL and leaves dir unchanged on failure", {
  bad <- tempfile(fileext = ".rar")
  writeBin(as.raw(1:100), bad)
  parent <- new_dir()
  dir <- file.path(parent, "out")
  expect_null(suppressMessages(extract_archive(bad, dir)))
  # empty, so a later dir.exists check retries
  expect_length(list.files(parent, all.files = TRUE, no.. = TRUE), 0)
  expect_null(suppressMessages(extract_archive(tempfile(), dir)))

  dir.create(dir)
  writeLines("keep", file.path(dir, "keep.txt"))
  expect_null(suppressMessages(extract_archive(bad, dir)))
  expect_equal(list.files(dir), "keep.txt")
})
