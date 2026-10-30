write_supplement <- function(respondents, tasks) {
  pooled <- dplyr::filter(respondents, study == 1 | (study == 2 & is_high_numeracy))
  samples <- list(
    study_1 = dplyr::filter(respondents, study == 1),
    study_2 = dplyr::filter(respondents, study == 2),
    study_2_high = dplyr::filter(respondents, study == 2, is_high_numeracy),
    study_3 = dplyr::filter(respondents, study == 3),
    study_3_high = dplyr::filter(respondents, study == 3, is_high_numeracy)
  )
  demographics <- lapply(names(samples), function(sample_name) {
    sample <- samples[[sample_name]] |>
      dplyr::mutate(
        party_group = dplyr::case_when(
          party_id <= 3 ~ "Democrat", party_id >= 5 ~ "Republican",
          party_id == 4 ~ "Independent"
        ),
        ideology_group = dplyr::case_when(
          ideology <= 2 ~ "Liberal", ideology >= 4 ~ "Conservative",
          ideology == 3 ~ "Moderate"
        )
      )
    columns <- c("party_group", "ideology_group", "education", "age_group", "is_female", "race_ethnicity")
    dplyr::bind_rows(lapply(columns, function(column) {
      values <- as.character(sample[[column]])
      counts <- as.data.frame(table(values, useNA = "ifany"), stringsAsFactors = FALSE)
      tibble::tibble(
        sample = sample_name, variable = column, category = as.character(counts$values),
        n = counts$Freq, n_observed = sum(!is.na(values)),
        share = ifelse(is.na(counts$values), NA_real_, counts$Freq / sum(!is.na(values)))
      )
    }))
  }) |>
    dplyr::bind_rows()
  write_table(demographics, "sample_characteristics")

  models <- list()
  balance <- list()
  for (study_id in 1:3) {
    sample <- dplyr::filter(respondents, study == study_id)
    for (outcome in c("party_id", "ideology", "education_code", "age_years", "is_female", "is_white")) {
      rhs <- if (study_id == 3 || outcome == "is_white") "gun_incentive" else "gun_congenial * gun_incentive"
      fit <- lm(reformulate(rhs, outcome), data = sample)
      label <- paste("balance", study_id, outcome, sep = "_")
      models[[label]] <- summarize_model(fit, label)
      model_summary <- broom::glance(fit)
      balance[[label]] <- tibble::tibble(
        study = study_id, outcome = outcome, formula = deparse(formula(fit)),
        n = nobs(fit), f_statistic = model_summary$statistic,
        df_numerator = model_summary$df, df_denominator = model_summary$df.residual,
        p_value = model_summary$p.value
      )
    }
  }
  write_table(dplyr::bind_rows(balance), "balance_tests")
  for (position in 0:1) {
    sample <- dplyr::filter(pooled, gun_ban == position)
    label <- paste0("gun_logit_position_", position)
    fit <- glm(gun_correct ~ gun_congenial * gun_incentive, data = sample, family = binomial())
    models[[label]] <- summarize_model(fit, label)
    fit <- lm(gun_rating ~ gun_congenial * gun_incentive, data = sample)
    label <- paste0("rating_position_", position)
    models[[label]] <- summarize_model(fit, label)
    models[[paste0(label, "_hc3")]] <- summarize_model(fit, label, "hc3")
    models[[paste0(label, "_cr2")]] <- summarize_model(fit, label, "cr2", sample)
  }
  fit <- lm(gun_rating ~ gun_congenial * gun_incentive, data = pooled)
  models$rating_pooled <- summarize_model(fit, "rating_pooled")
  models$rating_pooled_hc3 <- summarize_model(fit, "rating_pooled", "hc3")
  for (cell in c("a", "c")) {
    label <- paste0("recall_", cell)
    fit <- lm(reformulate("gun_congenial * gun_incentive", label), data = samples$study_1)
    models[[label]] <- summarize_model(fit, label)
    models[[paste0(label, "_hc3")]] <- summarize_model(fit, label, "hc3")
    models[[paste0(label, "_cr2")]] <- summarize_model(fit, label, "cr2", samples$study_1)
  }
  for (study_id in 2:3) {
    for (position in if (study_id == 2) 1 else 0:1) {
      sample <- dplyr::filter(respondents, study == study_id, wage_support == position)
      rhs <- if (study_id == 2) {
        "gun_congenial * gun_incentive * wage_congenial * wage_incentive"
      } else {
        "gun_incentive * wage_congenial * wage_incentive"
      }
      fit <- glm(reformulate(rhs, "wage_correct"), data = sample, family = binomial())
      label <- paste("wage_logit", study_id, position, sep = "_")
      models[[label]] <- summarize_model(fit, label)
    }
  }
  write_table(dplyr::bind_rows(models), "model_coefficients")

  by_numeracy <- dplyr::bind_rows(
    dplyr::mutate(tasks, numeracy_group = "all"),
    dplyr::mutate(tasks, numeracy_group = ifelse(is_high_numeracy, "high", "low"))
  ) |>
    dplyr::filter(task == "gun", !is.na(position), !is.na(congenial), !is.na(incentive))
  cells <- summarize_cells(by_numeracy, c("study", "numeracy_group", "position_label", "congenial", "incentive"))
  effects <- by_numeracy |>
    dplyr::group_by(study, numeracy_group, position_label, congenial) |>
    dplyr::group_modify(function(sample, key) {
      if (length(unique(sample$incentive)) != 2 || nrow(sample) < 4) {
        return(tibble::tibble())
      }
      sample$congenial <- key$congenial
      fit_contrasts(sample, factorial = FALSE)
    }) |>
    dplyr::ungroup()
  write_table(cells, "numeracy_cells")
  write_table(effects, "numeracy_incentive_effects")

  recall <- samples$study_1 |>
    dplyr::filter(gun_incentive == 0, !is.na(gun_congenial)) |>
    tidyr::pivot_longer(dplyr::starts_with("recall_"), names_to = "cell", values_to = "recalled")
  write_table(summarize_cells(recall, c("cell", "gun_congenial"), "recalled"), "recall_cells")

  response <- dplyr::bind_rows(
    dplyr::mutate(dplyr::filter(tasks, task == "gun", study == 1 | (study == 2 & is_high_numeracy)),
      sample = "pooled_1_2"
    ),
    dplyr::mutate(dplyr::filter(tasks, task == "gun", study %in% 2:3),
      sample = paste0("study_", study, ifelse(is_high_numeracy, "_high", "_low"))
    )
  ) |>
    dplyr::filter(!is_answer_missing, !is.na(position), !is.na(correct), !is.na(congenial), !is.na(incentive)) |>
    dplyr::mutate(is_congenial_answer = as.integer(correct == congenial)) |>
    dplyr::group_by(sample, position_label, incentive, congenial) |>
    dplyr::summarise(
      n = dplyr::n(), n_congenial = sum(is_congenial_answer),
      congenial_share = n_congenial / n, response_odds = n_congenial / (n - n_congenial),
      .groups = "drop"
    )
  write_table(response, "response_bias")
  write_table(
    response |>
      dplyr::group_by(sample, position_label, incentive) |>
      dplyr::summarise(
        n = sum(n), n_congenial = sum(n_congenial),
        response_odds = n_congenial / (n - n_congenial), .groups = "drop"
      ),
    "response_bias_pooled"
  )
  confidence <- tasks |>
    dplyr::filter(study == 3, !is.na(incentive), !is.na(confidence), !is.na(correct)) |>
    dplyr::count(task, incentive, confidence, correct, name = "n") |>
    dplyr::group_by(task, incentive) |>
    dplyr::mutate(share = n / sum(n), denominator = sum(n)) |>
    dplyr::ungroup()
  write_table(confidence, "confidence_joint")

  flows <- respondents |>
    dplyr::mutate(
      numeracy_group = ifelse(is_high_numeracy, "high", "low"),
      gun_version = ifelse(study == 3, "uncongenial", ifelse(gun_anti == 1, "anti_gun", "pro_gun"))
    ) |>
    dplyr::group_by(study, gun_version, gun_incentive, numeracy_group) |>
    dplyr::summarise(
      n_archived = dplyr::n(), n_position = sum(!is.na(gun_ban)),
      n_supporters = sum(gun_ban == 0, na.rm = TRUE),
      n_opponents = sum(gun_ban == 1, na.rm = TRUE),
      n_outcome = sum(!is_gun_answer_missing), .groups = "drop"
    )
  write_table(flows, "participant_flow")
  write_miscellaneous(respondents, pooled)
}

write_miscellaneous <- function(respondents, pooled) {
  attitudes <- respondents |>
    tidyr::pivot_longer(
      c(gun_ban, wage_support, gun_correct, wage_correct),
      names_to = "variable", values_to = "value"
    ) |>
    dplyr::group_by(study, variable) |>
    dplyr::summarise(n = sum(!is.na(value)), estimate = mean(value, na.rm = TRUE), .groups = "drop")
  write_table(attitudes, "overall_means")
  rating_tests <- list()
  for (position in c("all", "0", "1")) {
    for (incentive in c("all", "0", "1")) {
      for (correct_only in c(FALSE, TRUE)) {
        sample <- pooled
        if (position != "all") sample <- dplyr::filter(sample, gun_ban == as.numeric(position))
        if (incentive != "all") sample <- dplyr::filter(sample, gun_incentive == as.numeric(incentive))
        if (correct_only) sample <- dplyr::filter(sample, gun_correct == 1)
        fit <- t.test(gun_rating ~ gun_congenial, data = sample, alternative = "less")
        rating_tests[[length(rating_tests) + 1]] <- tibble::tibble(
          position = position, incentive = incentive, correct_only = correct_only,
          estimate = unname(diff(fit$estimate)), std_error = fit$stderr,
          statistic = -unname(fit$statistic), df = unname(fit$parameter), p_one_sided = fit$p.value
        )
      }
    }
  }
  write_table(dplyr::bind_rows(rating_tests), "rating_welch_tests")
  items <- pooled[c("gun_well_done", "gun_convincing")]
  items <- items[complete.cases(items), ]
  alpha <- psy::cronbach(items)$alpha
  write_table(tibble::tibble(
    n = nrow(items), alpha = alpha,
    item_correlation = cor(items[[1]], items[[2]])
  ), "rating_reliability")
}
