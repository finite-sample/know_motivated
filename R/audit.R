run_original <- function(script, recover_wage = FALSE) {
  original <- new.env(parent = globalenv())
  original$load <- function(file, ...) {
    target <- parent.frame()
    loaded <- base::load(file.path(raw_dir, file), envir = target)
    if (recover_wage && file == "Study2.RData") target$df2 <- reconstruct_wage(target$df2)
    invisible(loaded)
  }
  original$source <- function(file, ...) base::sys.source(file.path(raw_dir, file), envir = parent.frame())
  original$setwd <- function(dir) invisible(getwd())
  prefix <- if (recover_wage) "recovered_" else "original_"
  grDevices::pdf(file.path(build_dir, paste0(prefix, script, ".pdf")))
  on.exit(grDevices::dev.off(), add = TRUE)
  output <- capture.output(suppressWarnings(sys.source(file.path(raw_dir, paste0(script, ".R")), envir = original)))
  writeLines(output, file.path(build_dir, paste0(prefix, script, ".txt")))
  original
}

write_audit <- function(respondents, tasks) {
  replication <- readRDS(file.path(build_dir, "replication_respondents.rds"))
  missingness <- tasks |>
    dplyr::group_by(study, task, incentive) |>
    dplyr::summarise(
      n_archived = dplyr::n(), n_missing_position = sum(is.na(position)),
      n_missing_outcome = sum(is.na(correct)), n_missing_congeniality = sum(is.na(congenial)),
      .groups = "drop"
    )
  write_table(missingness, "missingness_by_assignment")
  allocations <- respondents |>
    dplyr::filter(study %in% 2:3) |>
    dplyr::count(study, gun_incentive, wage_incentive, .drop = FALSE) |>
    tidyr::complete(study, gun_incentive = 0:1, wage_incentive = 0:1, fill = list(n = 0))
  write_table(allocations, "task_assignments")
  versions <- respondents |>
    dplyr::filter(study == 2) |>
    dplyr::count(gun_anti, wage_pro) |>
    tidyr::complete(gun_anti = 0:1, wage_pro = 0:1, fill = list(n = 0))
  write_table(versions, "study_2_versions")

  cells <- readr::read_csv(file.path(table_dir, "accuracy_cells.csv"), show_col_types = FALSE)
  published <- readr::read_csv("docs/published_accuracy.csv", show_col_types = FALSE)
  replication_cells <- readr::read_csv(file.path(table_dir, "replication_accuracy_cells.csv"), show_col_types = FALSE)
  comparison <- dplyr::left_join(published, replication_cells,
    by = c("exhibit", "position_label", "congenial", "incentive"),
    relationship = "one-to-one"
  ) |>
    dplyr::mutate(
      reproduced_pct = 100 * estimate, difference_pp = reproduced_pct - published_pct,
      agrees_at_printed_precision = abs(difference_pp) < .051
    )
  stopifnot(nrow(comparison) == nrow(published), !anyNA(comparison$estimate))
  write_table(comparison, "published_accuracy_comparison")

  released <- read_studies(raw_dir, use_survey = FALSE)
  release_comparison <- comparison
  release_comparison$dataverse_pct <- NA_real_
  for (spec in list(c("figure_si_7", "fig.si7"), c("figure_si_8", "fig.si8"), c("figure_4", "fig4"))) {
    original <- run_original(spec[2])
    for (suffix in c("sup", "opp")) {
      group <- if (suffix == "sup") "Wage supporters" else "Wage opponents"
      selected <- which(release_comparison$exhibit == spec[1] & release_comparison$position_label == group)
      if (length(selected) == 0) next
      selected <- selected[order(release_comparison$incentive[selected], release_comparison$congenial[selected])]
      release_comparison$dataverse_pct[selected] <- original[[paste0("cvd.", suffix)]]
    }
  }
  write_table(dplyr::filter(release_comparison, !is.na(dataverse_pct)), "wage_source_comparison")
  recovered_sample <- dplyr::filter(respondents, study == 2)
  released_sample <- dplyr::filter(released, study == 2)
  recovery <- lapply(c("wage_pro", "wage_incentive", "wage_correct", "wage_congenial"), function(variable) {
    tibble::tibble(
      variable = variable,
      changed = sum(recovered_sample[[variable]] != released_sample[[variable]], na.rm = TRUE),
      released_ones = sum(released_sample[[variable]] == 1, na.rm = TRUE),
      recovered_ones = sum(recovered_sample[[variable]] == 1, na.rm = TRUE)
    )
  }) |>
    dplyr::bind_rows()
  write_table(recovery, "study_2_source_recovery")

  original_ratings <- run_original("fig5")
  repairs <- lapply(c("Carry supporters", "Carry opponents"), function(group) {
    suffix <- if (group == "Carry supporters") "sup" else "opp"
    sample <- dplyr::filter(
      replication, study == 1 | (study == 2 & is_high_numeracy),
      gun_ban == ifelse(group == "Carry supporters", 0, 1)
    ) |>
      dplyr::mutate(congenial = gun_congenial, incentive = gun_incentive)
    fit <- estimatr::lm_robust(gun_rating ~ congenial * incentive, data = sample, se_type = "HC2")
    grid <- emmeans::emmeans(fit, ~ congenial * incentive, at = list(congenial = 0:1, incentive = 0:1), df = Inf)
    corrected <- emmeans::contrast(grid, method = list(no_incentive = c(-1, 1, 0, 0), incentive = c(0, 0, -1, 1))) |>
      summary(infer = c(TRUE, TRUE), level = .9, adjust = "none") |>
      tidy_inference()
    corrected |>
      dplyr::mutate(
        position_label = group,
        archived_std_error = original_ratings[[paste0("se.diff.", suffix)]][2:3]
      )
  }) |>
    dplyr::bind_rows()
  write_table(repairs, "rating_standard_error_repair")
  original_wage <- run_original("fig.si7", recover_wage = TRUE)
  wage_cells <- dplyr::filter(cells, exhibit == "figure_si_7") |>
    dplyr::arrange(incentive, congenial) |>
    dplyr::mutate(original_script_n = original_wage$N.sup, original_script_std_error_pct = original_wage$se.sup)
  wage_sample <- tasks |>
    dplyr::filter(task == "wage", study == 2, position == 1)
  wage_fit <- estimatr::lm_robust(correct ~ congenial * incentive, data = wage_sample, se_type = "HC0")
  wage_grid <- emmeans::emmeans(wage_fit, ~ congenial * incentive, at = list(congenial = 0:1, incentive = 0:1))
  wage_errors <- tidy_inference(summary(wage_grid)) |>
    dplyr::arrange(incentive, congenial)
  wage_cells$corrected_hc0_std_error_pct <- 100 * wage_errors$std_error
  write_table(wage_cells, "wage_denominator_repair")

  pooled <- dplyr::filter(respondents, study == 1 | (study == 2 & is_high_numeracy))
  rating_sample <- pooled |>
    dplyr::mutate(congenial = gun_congenial, incentive = gun_incentive)
  write_table(fit_contrasts(rating_sample, "gun_rating"), "rating_pooled_contrasts")
  invisible(run_original("table_and_misc_numbers"))
  worldview <- lapply(c("policy_congeniality", "worldview_same_sample", "worldview_all"), function(coding) {
    sample <- pooled |>
      dplyr::filter(!is.na(ideological_group)) |>
      dplyr::mutate(
        correct = gun_correct, incentive = gun_incentive,
        congenial = if (coding == "policy_congeniality") gun_congenial else gun_worldview_congenial
      )
    if (coding == "worldview_same_sample") sample <- dplyr::filter(sample, !is.na(gun_ban))
    sample |>
      dplyr::group_by(ideological_group) |>
      dplyr::group_modify(~ fit_contrasts(.x)) |>
      dplyr::ungroup() |>
      dplyr::mutate(coding = coding)
  }) |>
    dplyr::bind_rows()
  write_table(worldview, "worldview_coding_comparison")

  scopes <- c("published_pool", "study_1", "study_2_high", "all_numeracy", "study_adjusted")
  sensitivity <- lapply(scopes, function(scope) {
    sample <- dplyr::filter(respondents, study %in% 1:2, !is.na(gun_ban))
    if (scope %in% c("published_pool", "study_adjusted")) {
      sample <- dplyr::filter(sample, study == 1 | is_high_numeracy)
    }
    if (scope == "study_1") sample <- dplyr::filter(sample, study == 1)
    if (scope == "study_2_high") sample <- dplyr::filter(sample, study == 2, is_high_numeracy)
    rhs <- if (scope == "study_adjusted") {
      "gun_congenial * gun_incentive + factor(study)"
    } else {
      "gun_congenial * gun_incentive"
    }
    sample |>
      dplyr::group_by(gun_ban) |>
      dplyr::group_modify(function(sample, key) {
        fit <- estimatr::lm_robust(reformulate(rhs, "gun_correct"), data = sample, se_type = "HC3")
        broom::tidy(fit) |>
          dplyr::filter(term == "gun_congenial:gun_incentive")
      }) |>
      dplyr::ungroup() |>
      dplyr::mutate(scope = scope)
  }) |>
    dplyr::bind_rows()
  names(sensitivity) <- gsub("[.]", "_", names(sensitivity))
  write_table(sensitivity, "gun_specification_checks")

  diagnostics <- lapply(0:1, function(position) {
    sample <- dplyr::filter(pooled, gun_ban == position)
    fit <- lm(gun_correct ~ gun_congenial * gun_incentive, data = sample)
    deleted <- dfbeta(fit)[, "gun_congenial:gun_incentive"]
    tibble::tibble(
      position = position, n = nobs(fit), rank = fit$rank,
      condition_number = kappa(model.matrix(fit)), max_leverage = max(hatvalues(fit)),
      max_cooks_distance = max(cooks.distance(fit)),
      interaction = coef(fit)[["gun_congenial:gun_incentive"]],
      leave_one_out_min = min(interaction - deleted), leave_one_out_max = max(interaction - deleted)
    )
  }) |>
    dplyr::bind_rows()
  write_table(diagnostics, "gun_influence_checks")
  multiplicity <- readr::read_csv(file.path(table_dir, "accuracy_contrasts.csv"), show_col_types = FALSE) |>
    dplyr::filter(
      exhibit %in% c("figure_2", "figure_3", "figure_4"), inference == "primary",
      contrast == "interaction" | exhibit == "figure_3"
    ) |>
    dplyr::mutate(
      p_holm = p.adjust(p_two_sided, method = "holm"),
      family = "Six main task-by-policy subgroup incentive contrasts; exploratory"
    )
  write_table(multiplicity, "multiplicity_check")
  write_balance_checks(respondents)
  write_source_checks(respondents, replication)
}

write_source_checks <- function(respondents, replication) {
  changes <- lapply(c("party_id", "numeracy_count", "age_years", "age_group"), function(variable) {
    changed <- respondents[[variable]] != replication[[variable]]
    tibble::tibble(
      study = respondents$study, variable = variable,
      is_changed = changed
    ) |>
      dplyr::group_by(study, variable) |>
      dplyr::summarise(n_changed = sum(is_changed, na.rm = TRUE), .groups = "drop")
  }) |>
    dplyr::bind_rows()
  write_table(changes, "raw_coding_changes")
  flows <- lapply(1:3, function(study) {
    survey <- read_survey(study)
    included <- survey_inclusion(survey, study)
    tibble::tibble(
      study = study, n_raw = nrow(survey), n_included = sum(included),
      n_excluded = sum(!included),
      n_gun_answer_missing_included = sum(rowSums(!is.na(survey[included, paste0("cvd", 1:4)])) == 0)
    )
  }) |>
    dplyr::bind_rows()
  write_table(flows, "survey_flow")
  workers <- respondents |>
    dplyr::group_by(study) |>
    dplyr::summarise(
      n_records = dplyr::n(), n_with_worker_id = sum(has_worker_id),
      n_identified_workers = dplyr::n_distinct(participant_key[has_worker_id]),
      n_repeat_records = sum(duplicated(participant_key[has_worker_id])), .groups = "drop"
    )
  write_table(workers, "participant_identity")
  repeated_workers <- respondents |>
    dplyr::filter(study == 1) |>
    dplyr::count(participant_key) |>
    dplyr::filter(n > 1) |>
    dplyr::pull(participant_key)
  sensitivity <- list()
  specifications <- c(
    "published_coding", "corrected_coding", "worker_clusters", "observed_answers",
    "first_participation", "exclude_repeated_workers"
  )
  for (specification in specifications) {
    sample <- if (specification == "published_coding") replication else respondents
    sample <- dplyr::filter(sample, study == 1 | (study == 2 & is_high_numeracy))
    if (specification == "observed_answers") sample <- dplyr::filter(sample, !is_gun_answer_missing)
    if (specification == "first_participation") sample <- dplyr::filter(sample, worker_attempt == 1)
    if (specification == "exclude_repeated_workers") {
      sample <- dplyr::filter(sample, !participant_key %in% repeated_workers)
    }
    for (outcome in c("gun_correct", "gun_rating")) {
      for (position in 0:1) {
        selected <- dplyr::filter(sample, gun_ban == position)
        formula <- reformulate("gun_congenial * gun_incentive", outcome)
        clustered <- specification %in% c(
          "worker_clusters", "observed_answers", "first_participation", "exclude_repeated_workers"
        )
        fit <- if (clustered) {
          estimatr::lm_robust(formula, data = selected, clusters = participant_key, se_type = "CR2")
        } else {
          estimatr::lm_robust(formula, data = selected, se_type = "HC2")
        }
        sensitivity[[length(sensitivity) + 1]] <- broom::tidy(fit) |>
          dplyr::filter(term == "gun_congenial:gun_incentive") |>
          dplyr::mutate(specification = specification, outcome = outcome, position = position, n = nobs(fit))
      }
    }
  }
  sensitivity <- dplyr::bind_rows(sensitivity)
  names(sensitivity) <- gsub("[.]", "_", names(sensitivity))
  write_table(sensitivity, "source_coding_sensitivity")
}

write_balance_checks <- function(respondents) {
  results <- list()
  for (study_id in 1:2) {
    sample <- dplyr::filter(respondents, study == study_id)
    for (specification in c("incentive_only", "policy_factorial", "assigned_version_factorial")) {
      rhs <- switch(specification,
        incentive_only = "gun_incentive",
        policy_factorial = "gun_congenial * gun_incentive",
        assigned_version_factorial = "gun_anti * gun_incentive"
      )
      fit <- lm(reformulate(rhs, "is_white"), data = sample)
      results[[length(results) + 1]] <- broom::glance(fit) |>
        dplyr::select(nobs, statistic, df, df.residual, p.value) |>
        dplyr::mutate(study = study_id, specification = specification)
    }
  }
  results <- dplyr::bind_rows(results)
  names(results) <- gsub("[.]", "_", names(results))
  write_table(results, "race_balance_checks")
}
