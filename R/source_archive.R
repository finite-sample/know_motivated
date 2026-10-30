extract_surveys <- function(archive) {
  expected <- readr::read_csv(project_file("docs", "recovery_sources.csv"), show_col_types = FALSE)$sha256[1]
  stopifnot(digest::digest(file = archive, algo = "sha256") == expected)
  inventory <- readr::read_csv(project_file("docs", "archive_inventory.csv"), show_col_types = FALSE)
  selected <- dplyr::filter(inventory, !is.na(output))
  temporary <- tempfile("survey_archive_")
  dir.create(temporary)
  on.exit(unlink(temporary, recursive = TRUE), add = TRUE)
  utils::unzip(archive, files = selected$member, exdir = temporary)
  tables <- list()
  dictionaries <- list()
  for (i in seq_len(nrow(selected))) {
    input <- file.path(temporary, selected$member[i])
    stopifnot(digest::digest(file = input, algo = "sha256") == selected$sha256[i])
    if (selected$role[i] == "questionnaire") {
      dir.create(dirname(selected$output[i]), recursive = TRUE, showWarnings = FALSE)
      stopifnot(file.copy(input, selected$output[i], overwrite = TRUE))
      next
    }
    is_survey <- selected$role[i] == "survey_export"
    delimiter <- if (grepl("qualtrics_final", input)) "\t" else ","
    records <- read.table(input,
      header = TRUE, sep = delimiter, quote = "\"", comment.char = "",
      check.names = FALSE, colClasses = "character", na.strings = c("", "NA"),
      fileEncoding = "UTF-8-BOM", fill = TRUE
    )
    source_names <- names(records)
    labels <- if (is_survey) unname(as.character(records[1, ])) else source_names
    if (is_survey) records <- records[-1, , drop = FALSE]
    names(records) <- tolower(source_names)
    names(records)[names(records) == ""] <- paste0("unnamed_", which(names(records) == ""))
    stopifnot(!anyDuplicated(names(records)))
    date_column <- if ("v3" %in% names(records)) "v3" else "startdate"
    date_value <- records[[date_column]]
    date_format <- if (grepl("qualtrics", input, ignore.case = TRUE)) "%m/%d/%y %H:%M" else "%Y-%m-%d %H:%M:%S"
    started_at <- as.POSIXct(date_value, format = date_format, tz = "UTC")
    records$interview_year <- as.integer(format(started_at, "%Y"))
    stopifnot(!anyNA(records$interview_year))
    records$source_row <- seq_len(nrow(records))
    records$worker_attempt <- 1L
    if (is_survey && grepl("study_1[.]csv$", selected$output[i])) {
      records$worker_attempt <- NA_integer_
      eligible <- which(survey_inclusion(records, 1))
      eligible <- eligible[order(started_at[eligible], eligible)]
      records$worker_attempt[eligible] <- ave(seq_along(eligible), records$workerid[eligible], FUN = seq_along)
    }
    tables[[selected$output[i]]] <- records
    dictionaries[[selected$output[i]]] <- tibble::tibble(
      file = selected$output[i], source_name = source_names,
      column = names(records)[seq_along(source_names)], label = labels
    )
  }
  aliases <- c(
    v1 = "response", responseid = "response", workerid = "worker", assignmentid = "assignment",
    psid = "panel", rid = "panel_response", risn = "panel_serial", custom1 = "panel_custom"
  )
  identifiers <- lapply(unique(aliases), function(kind) {
    columns <- names(aliases)[aliases == kind]
    values <- unlist(lapply(tables, function(records) unlist(records[intersect(names(records), columns)])))
    sort(unique(values[!is.na(values)]), method = "radix")
  })
  names(identifiers) <- unique(aliases)
  linkage <- list()
  column_records <- list()
  for (output in names(tables)) {
    records <- tables[[output]]
    if (grepl("/surveys/", output)) {
      study <- as.integer(sub(".*study_([123])[.]csv", "\\1", output))
      original <- new.env(parent = emptyenv())
      load(file.path(raw_dir, paste0("Study", study, ".RData")), envir = original)
      linkage[[study]] <- link_survey(records, original[[paste0("df", study)]], study)
    }
    dictionary <- dictionaries[[output]]
    dictionary$action <- "retain"
    dictionary$reason <- "Research response or non-identifying survey metadata"
    for (column in intersect(names(records), names(aliases))) {
      kind <- aliases[[column]]
      index <- match(records[[column]], identifiers[[kind]])
      records[[column]] <- ifelse(is.na(index), NA_character_, sprintf("%s_%06d", kind, index))
      dictionary$action[dictionary$column == column] <- "pseudonymize"
      dictionary$reason[dictionary$column == column] <- "Consistent anonymous identifier across research exports"
    }
    removed <- grepl(
      "^browser|^ipaddress$|^ip_address$|^comments$|^recipient|^locationlatitude$|^locationlongitude$",
      names(records)
    ) | names(records) %in% c("v2", "v3", "v4", "responseset", "startdate", "enddate", "date")
    dictionary$action[dictionary$column %in% names(records)[removed]] <- "remove"
    dictionary$reason[dictionary$column %in% names(records)[removed]] <- "Direct identifier or administrative metadata"
    dictionary <- dplyr::bind_rows(dictionary, tibble::tibble(
      file = output, source_name = NA_character_, column = "interview_year",
      label = "Calendar year of survey start", action = "derive",
      reason = "Year extracted from source timestamp; exact timestamp removed"
    ))
    dictionary <- dplyr::bind_rows(dictionary, tibble::tibble(
      file = output, source_name = NA_character_, column = "worker_attempt",
      label = "Eligible gun-task participation order within worker",
      action = "derive", reason = paste(
        "Chronological eligible attempts in Study 1 survey export;",
        "other exports use 1 and do not identify repeat participation"
      )
    ))
    column_records[[output]] <- dictionary
    dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(records[!removed], output, na = "")
  }
  readr::write_csv(dplyr::bind_rows(linkage), "data/extracted/surveys/respondent_linkage.csv")
  readr::write_csv(dplyr::bind_rows(column_records), "docs/survey_columns.csv")
  message("Extracted full survey exports, historical coding files, questionnaires, and respondent linkage.")
  invisible(NULL)
}
