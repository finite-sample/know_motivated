write_paper_numbers <- function(respondents) {
  state <- new.env(parent = emptyenv())
  state$ledger <- list()
  key_part <- function(value) gsub("[^a-z0-9]+", "_", tolower(as.character(value)))
  emit <- function(key, value, source) {
    stopifnot(length(value) == 1, !is.na(value))
    state$ledger[[length(state$ledger) + 1L]] <- tibble::tibble(key = key, value = as.character(value), source = source)
  }
  read <- function(name) readr::read_csv(file.path(table_dir, paste0(name, ".csv")), show_col_types = FALSE)
  rows <- function(records, prefix, keys, source, scale = 1) {
    for (i in seq_len(nrow(records))) {
      row <- records[i, ]
      key <- paste(c(prefix, vapply(row[keys], key_part, character(1))), collapse = ".")
      for (metric in intersect(c("estimate", "std_error", "conf_low", "conf_high", "response_odds"), names(row))) {
        if (is.na(row[[metric]])) next
        emit(paste(key, metric, sep = "."), sprintf("%.2f", scale * row[[metric]]), source)
        emit(paste(key, metric, "one", sep = "."), sprintf("%.1f", scale * row[[metric]]), source)
      }
      if ("estimate" %in% names(row) && !is.na(row$estimate)) {
        emit(paste0(key, ".magnitude"), sprintf("%.1f", abs(scale * row$estimate)), source)
      }
      if ("n" %in% names(row)) emit(paste0(key, ".n"), row$n, source)
      if ("p_two_sided" %in% names(row)) {
        p <- row$p_two_sided
        emit(paste0(key, ".p"), ifelse(p < .001, "<0.001", sprintf("=%.3f", p)), source)
      }
      if (all(c("conf_low", "conf_high") %in% names(row)) && !anyNA(row[c("conf_low", "conf_high")])) {
        emit(paste0(key, ".ci"), sprintf("[%.2f, %.2f]", scale * row$conf_low, scale * row$conf_high), source)
      }
    }
  }
  rows(
    dplyr::filter(read("accuracy_contrasts"), inference == "primary"), "accuracy",
    c("exhibit", "position_label", "contrast"), "tabs/accuracy_contrasts.csv", 100
  )
  rows(
    read("accuracy_cells"), "cell", c("exhibit", "position_label", "congenial", "incentive"),
    "tabs/accuracy_cells.csv", 100
  )
  rows(read("rating_contrasts"), "rating", c("position_label", "contrast"), "tabs/rating_contrasts.csv")
  rows(
    dplyr::mutate(read("rating_pooled_contrasts"), position_label = "pooled"), "rating",
    c("position_label", "contrast"), "tabs/rating_pooled_contrasts.csv"
  )
  rows(read("recall_cells"), "recall", c("cell", "gun_congenial"), "tabs/recall_cells.csv")
  rows(
    read("response_bias_pooled"), "odds", c("sample", "position_label", "incentive"),
    "tabs/response_bias_pooled.csv"
  )
  rows(read("overall_means"), "mean", c("study", "variable"), "tabs/overall_means.csv", 100)
  rows(
    read("rating_welch_tests"), "welch", c("position", "incentive", "correct_only"),
    "tabs/rating_welch_tests.csv"
  )
  rows(read("model_coefficients"), "model", c("model", "covariance", "term"), "tabs/model_coefficients.csv")
  for (group in c("Liberal Democrat", "Conservative Republican")) {
    sample <- dplyr::filter(respondents, ideological_group == group)
    value <- if (group == "Liberal Democrat") {
      mean(sample$gun_ban == 0, na.rm = TRUE)
    } else {
      mean(sample$gun_ban == 1, na.rm = TRUE)
    }
    emit(
      paste0("worldview.", key_part(group), ".discordant"), sprintf("%.1f", 100 * value),
      "data/build/respondents.rds"
    )
  }
  for (study in 1:3) {
    sample <- dplyr::filter(respondents, study == !!study)
    emit(paste0("sample.", study, ".n"), nrow(sample), "data/build/respondents.rds")
    emit(paste0("sample.", study, ".position"), sum(!is.na(sample$gun_ban)), "data/build/respondents.rds")
    emit(paste0("sample.", study, ".high"), sum(sample$is_high_numeracy), "data/build/respondents.rds")
    emit(
      paste0("sample.", study, ".high_pct"), sprintf("%.1f", 100 * mean(sample$is_high_numeracy)),
      "data/build/respondents.rds"
    )
    emit(
      paste0("sample.", study, ".pool"), sum(sample$is_high_numeracy & !is.na(sample$gun_ban)),
      "data/build/respondents.rds"
    )
    emit(
      paste0("sample.", study, ".wage_opponents"), sum(sample$wage_support == 0, na.rm = TRUE),
      "data/build/respondents.rds"
    )
  }
  survey_one <- read_survey(1)
  emit(
    "sample.1.roster", sum(survey_one$condition %in% "United States" & !is.na(survey_one$workerid)),
    "data/extracted/surveys/study_1.csv"
  )
  for (high in c(FALSE, TRUE)) {
    sample <- dplyr::filter(respondents, study == 2, is_high_numeracy == high, !is.na(ideological_group))
    value <- stats::cor(as.numeric(sample$ideological_group == "Liberal Democrat"), sample$gun_ban,
      use = "complete.obs"
    )
    emit(
      paste0("worldview.study_2.", ifelse(high, "high", "low"), ".correlation"), sprintf("%.2f", value),
      "data/build/respondents.rds"
    )
  }
  emit(
    "sample.1.workers", dplyr::n_distinct(respondents$participant_key[respondents$study == 1]),
    "data/build/respondents.rds"
  )
  emit("rating.alpha", sprintf("%.2f", read("rating_reliability")$alpha), "tabs/rating_reliability.csv")
  confidence <- read("confidence_joint") |>
    dplyr::filter(incentive == 0, confidence == 5)
  for (task in unique(confidence$task)) {
    sample <- dplyr::filter(confidence, task == !!task)
    emit(
      paste0("confidence.", task, ".certain"), sprintf("%.1f", 100 * sum(sample$share)),
      "tabs/confidence_joint.csv"
    )
    emit(
      paste0("confidence.", task, ".incorrect"), sprintf("%.1f", 100 * sample$share[sample$correct == 0]),
      "tabs/confidence_joint.csv"
    )
  }
  ledger <- dplyr::bind_rows(state$ledger)
  stopifnot(!anyDuplicated(ledger$key))
  paper_files <- list.files("paper", pattern = "[.]tex$", full.names = TRUE)
  text <- paste(unlist(lapply(paper_files, readLines)), collapse = "\n")
  references <- regmatches(text, gregexpr("\\\\result\\{[^}]+\\}", text))[[1]]
  requested <- unique(sub("\\\\result\\{([^}]+)\\}", "\\1", references))
  missing <- setdiff(requested, ledger$key)
  if (length(missing)) stop("Missing manuscript values: ", paste(missing, collapse = ", "))
  ledger <- dplyr::filter(ledger, key %in% requested)
  write_table(ledger, "paper_numbers")
  writeLines(
    sprintf("\\expandafter\\def\\csname result:%s\\endcsname{%s}", ledger$key, ledger$value),
    file.path(table_dir, "paper_numbers.tex")
  )
}
