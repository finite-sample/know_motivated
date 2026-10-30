write_worker_exclusion <- function(respondents, tasks) {
  retained <- exclude_repeated_workers(respondents)
  retained_tasks <- dplyr::filter(tasks, respondent_key %in% retained$respondent_key)
  excluded <- dplyr::filter(respondents, !respondent_key %in% retained$respondent_key) |>
    dplyr::select(study, respondent_key, participant_key, worker_attempt)
  write_table(excluded, "worker_exclusions")
  counts <- dplyr::bind_rows(
    dplyr::mutate(respondents, specification = "full_sample"),
    dplyr::mutate(retained, specification = "exclude_repeated_workers")
  ) |>
    dplyr::group_by(specification, study) |>
    dplyr::summarise(
      n_records = dplyr::n(), n_workers = dplyr::n_distinct(participant_key),
      n_policy_position = sum(!is.na(gun_ban)), .groups = "drop"
    )
  write_table(counts, "worker_exclusion_counts")

  affected <- c("figure_2", "figure_si_4", "figure_si_5")
  estimates <- estimate_exhibits(make_exhibit_samples(retained, retained_tasks)[affected])
  read <- function(name) readr::read_csv(file.path(table_dir, paste0(name, ".csv")), show_col_types = FALSE)
  combine <- function(full, excluded) {
    dplyr::bind_rows(
      dplyr::mutate(full, specification = "full_sample"),
      dplyr::mutate(excluded, specification = "exclude_repeated_workers")
    )
  }
  cells <- combine(dplyr::filter(read("accuracy_cells"), exhibit %in% affected), estimates$cells)
  contrasts <- combine(dplyr::filter(read("accuracy_contrasts"), exhibit %in% affected), estimates$contrasts)
  write_table(cells, "worker_exclusion_accuracy_cells")
  write_table(contrasts, "worker_exclusion_accuracy_contrasts")
  ratings <- estimate_ratings(retained)
  write_table(combine(read("rating_cells"), ratings$cells), "worker_exclusion_rating_cells")
  pooled <- retained |>
    dplyr::filter(study == 1 | (study == 2 & is_high_numeracy), !is.na(gun_ban)) |>
    dplyr::mutate(congenial = gun_congenial, incentive = gun_incentive)
  pooled_contrasts <- fit_contrasts(pooled, "gun_rating") |>
    dplyr::mutate(position_label = "Pooled")
  rating_contrasts <- combine(
    dplyr::bind_rows(
      read("rating_contrasts"), dplyr::mutate(read("rating_pooled_contrasts"), position_label = "Pooled")
    ),
    dplyr::bind_rows(ratings$contrasts, pooled_contrasts)
  )
  write_table(rating_contrasts, "worker_exclusion_rating_contrasts")
  summary <- dplyr::bind_rows(
    contrasts |>
      dplyr::filter(exhibit == "figure_2", contrast == "interaction", inference == "primary") |>
      dplyr::mutate(
        outcome = "Correctness (percentage points)",
        dplyr::across(c(estimate, std_error, conf_low, conf_high), ~ .x * 100)
      ),
    rating_contrasts |>
      dplyr::filter(contrast == "interaction") |>
      dplyr::mutate(exhibit = "figure_5", outcome = "Ratings (0-10 points)")
  )
  summary <- dplyr::arrange(
    summary, outcome, position_label, match(specification, c("full_sample", "exclude_repeated_workers"))
  )
  write_table(summary, "worker_exclusion_summary")
  invisible(summary)
}
