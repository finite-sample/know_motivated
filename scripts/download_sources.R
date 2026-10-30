source("scripts/00_config.R")
sources <- readr::read_csv("docs/sources.csv", show_col_types = FALSE)
for (i in seq_len(nrow(sources))) {
  path <- sources$path[i]
  if (file.exists(path)) {
    if (digest::digest(file = path, algo = "sha256") != sources$sha256[i]) {
      stop("Existing source differs from manifest: ", path)
    }
    next
  }
  if (is.na(sources$source_url[i])) stop("Missing recovered source: ", path, ". Run make extract with the source ZIP.")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary_path <- tempfile(tmpdir = dirname(path))
  download.file(sources$source_url[i], temporary_path, mode = "wb", method = "libcurl")
  if (digest::digest(file = temporary_path, algo = "sha256") != sources$sha256[i]) {
    unlink(temporary_path)
    stop("Downloaded source differs from pinned version: ", path)
  }
  stopifnot(file.rename(temporary_path, path))
}
verify_sources()
