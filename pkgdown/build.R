# Local site build:
#   Rscript pkgdown/build.R
# Needs MOSPI_KEY: the vignettes call the live API, and the HCES article downloads the NSS 62 CSV zip when it is missing.

# pkgdown renders every top-level .md as a public page; agent notes are internal
notes <- c("CLAUDE.md", "AGENTS.md")
# an interrupted build leaves notes renamed
stale <- file.exists(sprintf(".%s.hold", notes)) & !file.exists(notes)
file.rename(sprintf(".%s.hold", notes[stale]), notes[stale])
private <- intersect(notes, dir())
held <- sprintf(".%s.hold", private)
stopifnot(all(file.rename(private, held)))

tryCatch(
  {
    pkgdown::clean_site(force = TRUE)
    pkgdown::build_site(preview = FALSE, new_process = FALSE)
  },
  finally = stopifnot(all(file.rename(held, private)))
)

leaked <- intersect(paste0(tools::file_path_sans_ext(private), ".html"), dir("docs"))
if (length(leaked)) stop("Internal notes rendered into docs/: ", paste(leaked, collapse = ", "))
