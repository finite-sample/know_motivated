verify_sources <- function(manifest = "docs/sources.csv") {
  sources <- readr::read_csv(manifest, show_col_types = FALSE)
  for (i in seq_len(nrow(sources))) {
    path <- sources$path[i]
    if (!file.exists(path)) stop("Missing source: ", path, ". Run make download.")
    actual <- digest::digest(file = path, algo = "sha256")
    if (!identical(actual, sources$sha256[i])) stop("Source checksum mismatch: ", path)
  }
  invisible(sources)
}

read_studies <- function(raw_dir, use_survey = TRUE, correct_coding = TRUE) {
  linkage <- readr::read_csv(project_file("data", "extracted", "surveys", "respondent_linkage.csv"),
    show_col_types = FALSE
  )
  metadata <- list()
  studies <- lapply(1:3, function(study) {
    records <- readr::read_tsv(
      file.path(raw_dir, paste0("Study", study, ".tab")),
      na = c("NA", ""), show_col_types = FALSE
    )
    original <- new.env(parent = emptyenv())
    load(file.path(raw_dir, paste0("Study", study, ".RData")), envir = original)
    original <- original[[paste0("df", study)]]
    for (column in names(original)) {
      expected <- original[[column]]
      if (is.factor(expected)) expected <- as.character(expected)
      stopifnot(isTRUE(all.equal(records[[column]], expected, check.attributes = FALSE)))
    }
    stopifnot(nrow(records) == c(785, 947, 1062)[study], !anyDuplicated(records$respid))
    survey <- read_survey(study)
    selected <- linkage[linkage$study == study, ]
    selected <- selected[match(records$respid, selected$respondent_id), ]
    stopifnot(!anyNA(selected$source_row), !anyDuplicated(selected$source_row))
    survey <- survey[selected$source_row, ]
    if (use_survey) {
      reconstructed <- reconstruct_survey(survey, study, correct_coding)
      reconstructed$respid <- records$respid
      records <- reconstructed[names(records)]
    }
    worker <- survey[["workerid"]]
    if (is.null(worker)) worker <- rep(NA_character_, nrow(survey))
    participant <- ifelse(is.na(worker), paste(study, records$respid, sep = "_"), worker)
    metadata[[study]] <<- tibble::tibble(
      study = study, respondent_id = records$respid, source_row = selected$source_row,
      participant_key = participant, has_worker_id = !is.na(worker),
      worker_attempt = as.integer(survey$worker_attempt),
      is_gun_answer_missing = rowSums(!is.na(survey[paste0("cvd", 1:4)])) == 0,
      numeracy_answer_5 = survey$num5
    )
    records
  })
  respondents <- dplyr::bind_rows(studies)
  mapping <- readr::read_csv(project_file("docs", "variable_names.csv"), show_col_types = FALSE)
  stopifnot(setequal(names(respondents), mapping$source_name))
  names(respondents) <- mapping$analysis_name[match(names(respondents), mapping$source_name)]
  respondents <- dplyr::left_join(respondents, dplyr::bind_rows(metadata),
    by = c("study", "respondent_id"), relationship = "one-to-one"
  )
  respondents <- respondents |>
    dplyr::mutate(
      respondent_key = paste(study, respondent_id, sep = "_"),
      numeracy_share = numeracy_count / 5,
      is_high_numeracy = numeracy_count >= 4,
      gun_rating = (gun_well_done + gun_convincing) / 2,
      ideological_group = dplyr::case_when(
        party_id >= 5 & ideology >= 4 ~ "Conservative Republican",
        party_id <= 3 & ideology <= 2 ~ "Liberal Democrat",
        .default = NA_character_
      ),
      gun_worldview_congenial = dplyr::case_when(
        ideological_group == "Conservative Republican" ~ 1 - gun_anti,
        ideological_group == "Liberal Democrat" ~ gun_anti,
        .default = NA_real_
      ),
      education_code = match(education, c("HS or Less", "Some College", "College Degree", "Post-Graduate")),
      is_white = as.numeric(race_ethnicity == "White, Non-Hisp")
    )
  stopifnot(!anyDuplicated(respondents$respondent_key))
  stopifnot(all(respondents$numeracy_count == rowSums(respondents[paste0("numeracy_item_", 1:5)])))
  respondents
}

exclude_repeated_workers <- function(respondents) {
  repeated <- respondents |>
    dplyr::filter(study == 1, has_worker_id) |>
    dplyr::count(participant_key) |>
    dplyr::filter(n > 1) |>
    dplyr::pull(participant_key)
  dplyr::filter(respondents, study != 1 | !participant_key %in% repeated)
}

build_tasks <- function(respondents) {
  common <- c("study", "respondent_key", "participant_key", "numeracy_count", "is_high_numeracy")
  gun <- respondents |>
    dplyr::select(dplyr::all_of(common),
      position = gun_ban, congenial = gun_congenial,
      incentive = gun_incentive, correct = gun_correct, confidence = gun_confidence
    ) |>
    dplyr::mutate(is_answer_missing = respondents$is_gun_answer_missing) |>
    dplyr::mutate(task = "gun", position_label = dplyr::if_else(
      position == 0, "Carry supporters", "Carry opponents"
    ))
  wage <- respondents |>
    dplyr::filter(study %in% 2:3) |>
    dplyr::select(dplyr::all_of(common),
      position = wage_support, congenial = wage_congenial,
      incentive = wage_incentive, correct = wage_correct, confidence = wage_confidence
    ) |>
    dplyr::mutate(is_answer_missing = is.na(correct), task = "wage", position_label = dplyr::if_else(
      position == 0, "Wage opponents", "Wage supporters"
    ))
  tasks <- dplyr::bind_rows(gun, wage)
  stopifnot(nrow(tasks) == 2794 + 2009, !anyDuplicated(tasks[c("respondent_key", "task")]))
  tasks
}

write_table <- function(records, name) {
  readr::write_csv(records, file.path(table_dir, paste0(name, ".csv")), na = "")
}
