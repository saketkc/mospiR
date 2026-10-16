# Local site build; the HCES article needs NSS 62 data under data/hces, so CI cannot run it.
#   Rscript pkgdown/build.R
# Set MOSPI_KEY to evaluate the getting-started vignette against the live API.

stopifnot(dir.exists("data/hces"))

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
