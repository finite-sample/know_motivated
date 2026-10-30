tidy_inference <- function(result) {
  result <- as.data.frame(result)
  mapping <- c(
    emmean = "estimate", SE = "std_error", lower.CL = "conf_low",
    upper.CL = "conf_high", asymp.LCL = "conf_low", asymp.UCL = "conf_high",
    p.value = "p_two_sided", t.ratio = "statistic", z.ratio = "statistic"
  )
  for (column in intersect(names(mapping), names(result))) {
    names(result)[names(result) == column] <- mapping[[column]]
  }
  tibble::as_tibble(result)
}

uses_worker_clusters <- function(sample) {
  "participant_key" %in% names(sample) && any(startsWith(sample$participant_key, "worker_"))
}

summarize_cells <- function(records, groups, outcome = "correct", method = "primary") {
  records |>
    dplyr::group_by(dplyr::across(dplyr::all_of(groups))) |>
    dplyr::group_modify(function(sample, key) {
      observed_sample <- sample[!is.na(sample[[outcome]]), ]
      observed <- observed_sample[[outcome]]
      counts <- tibble::tibble(
        n_total = nrow(sample), n = length(observed),
        n_missing = nrow(sample) - length(observed)
      )
      if (length(observed) < 2) {
        return(dplyr::bind_cols(counts, tibble::tibble(
          estimate = mean(observed),
          std_error = NA_real_, conf_low = NA_real_, conf_high = NA_real_
        )))
      }
      observed_sample$value <- observed
      fit <- if (method == "primary" && uses_worker_clusters(observed_sample)) {
        estimatr::lm_robust(value ~ 1, data = observed_sample, clusters = participant_key, se_type = "CR2")
      } else {
        estimatr::lm_robust(value ~ 1, data = observed_sample, se_type = "HC2")
      }
      inference <- broom::tidy(fit) |>
        dplyr::transmute(estimate, std_error = std.error, conf_low = conf.low, conf_high = conf.high)
      dplyr::bind_cols(counts, inference)
    }) |>
    dplyr::ungroup()
}

fit_contrasts <- function(sample, outcome = "correct", factorial = TRUE, method = "primary") {
  stopifnot(method %in% c("primary", "hc2", "hc0_normal"))
  required <- c(outcome, "incentive", if (factorial) "congenial")
  sample <- sample[complete.cases(sample[required]), ]
  if (!factorial) stopifnot(length(unique(sample$congenial)) == 1L, unique(sample$congenial) %in% 0:1)
  rhs <- if (factorial) "congenial * incentive" else "incentive"
  if (method == "primary" && uses_worker_clusters(sample)) {
    hypotheses <- if (factorial) {
      c(
        congeniality_no_incentive = "congenial = 0",
        congeniality_incentive = "congenial + congenial:incentive = 0",
        interaction = "congenial:incentive = 0",
        incentive_uncongenial = "incentive = 0",
        incentive_congenial = "incentive + congenial:incentive = 0"
      )
    } else {
      label <- if (all(sample$congenial == 1)) "incentive_congenial" else "incentive_uncongenial"
      setNames("incentive = 0", label)
    }
    return(dplyr::bind_rows(lapply(names(hypotheses), function(label) {
      fit <- estimatr::lh_robust(reformulate(rhs, outcome),
        data = sample,
        clusters = participant_key, se_type = "CR2", linear_hypothesis = hypotheses[[label]]
      )
      broom::tidy(fit$lh) |>
        dplyr::transmute(
          contrast = label, estimate, std_error = std.error, df,
          conf_low = conf.low, conf_high = conf.high, statistic, p_two_sided = p.value,
          n = nrow(sample), inference = method, covariance = "CR2", confidence = .95
        )
    })))
  }
  fit <- estimatr::lm_robust(reformulate(rhs, outcome),
    data = sample,
    se_type = if (method == "hc0_normal") "HC0" else "HC2"
  )
  if (fit$rank != fit$k) stop("Requested treatment contrasts lack full cell support.")
  grid <- emmeans::emmeans(fit,
    specs = if (factorial) ~ congenial * incentive else ~incentive,
    at = list(congenial = 0:1, incentive = 0:1),
    df = if (method == "hc0_normal") Inf else fit$df[1]
  )
  contrasts <- if (factorial) {
    list(
      congeniality_no_incentive = c(-1, 1, 0, 0),
      congeniality_incentive = c(0, 0, -1, 1),
      interaction = c(1, -1, -1, 1),
      incentive_uncongenial = c(-1, 0, 1, 0),
      incentive_congenial = c(0, -1, 0, 1)
    )
  } else {
    label <- if (all(sample$congenial == 1, na.rm = TRUE)) "incentive_congenial" else "incentive_uncongenial"
    setNames(list(c(-1, 1)), label)
  }
  inference <- emmeans::contrast(grid, method = contrasts, adjust = "none") |>
    summary(infer = c(TRUE, TRUE), level = .95) |>
    tidy_inference()
  inference |>
    dplyr::mutate(
      n = nrow(sample), inference = method,
      covariance = ifelse(method == "hc0_normal", "HC0", "HC2"), confidence = .95
    )
}

make_exhibit_samples <- function(respondents, tasks) {
  pooled <- dplyr::filter(tasks, task == "gun", study == 1 | (study == 2 & is_high_numeracy))
  ideology <- dplyr::filter(respondents, study == 1 | (study == 2 & is_high_numeracy)) |>
    dplyr::transmute(study, respondent_key, participant_key,
      task = "gun", correct = gun_correct,
      congenial = gun_worldview_congenial, incentive = gun_incentive,
      position_label = ideological_group
    )
  list(
    figure_2 = pooled,
    figure_3 = dplyr::filter(tasks, task == "gun", study == 3),
    figure_4 = dplyr::filter(tasks, task == "wage"),
    figure_si_4 = ideology,
    figure_si_5 = dplyr::filter(tasks, task == "gun", study == 1),
    figure_si_6 = dplyr::filter(tasks, task == "gun", study == 2, is_high_numeracy),
    figure_si_7 = dplyr::filter(tasks, task == "wage", study == 2, position == 1),
    figure_si_8 = dplyr::filter(tasks, task == "wage", study == 3)
  )
}

estimate_exhibits <- function(samples, method = "primary") {
  cells <- list()
  contrasts <- list()
  for (exhibit in names(samples)) {
    sample <- samples[[exhibit]] |>
      dplyr::filter(!is.na(position_label), !is.na(congenial), !is.na(incentive))
    cells[[exhibit]] <- summarize_cells(sample, c("position_label", "congenial", "incentive"), method = method) |>
      dplyr::mutate(exhibit = exhibit, .before = 1)
    contrasts[[exhibit]] <- sample |>
      dplyr::group_by(position_label) |>
      dplyr::group_modify(function(sample, key) {
        dplyr::bind_rows(lapply(unique(c(method, "hc2", "hc0_normal")), function(method) {
          fit_contrasts(sample, factorial = exhibit != "figure_3", method = method)
        }))
      }) |>
      dplyr::ungroup() |>
      dplyr::mutate(exhibit = exhibit, .before = 1)
  }
  list(cells = dplyr::bind_rows(cells), contrasts = dplyr::bind_rows(contrasts))
}

estimate_ratings <- function(respondents) {
  sample <- respondents |>
    dplyr::filter(study == 1 | (study == 2 & is_high_numeracy), !is.na(gun_ban)) |>
    dplyr::mutate(
      position_label = dplyr::if_else(gun_ban == 0, "Carry supporters", "Carry opponents"),
      congenial = gun_congenial, incentive = gun_incentive
    )
  cells <- summarize_cells(sample, c("position_label", "congenial", "incentive"), "gun_rating")
  contrasts <- sample |>
    dplyr::group_by(position_label) |>
    dplyr::group_modify(function(sample, key) {
      fit <- estimatr::lm_robust(gun_rating ~ congenial,
        data = sample,
        clusters = participant_key, se_type = "CR2"
      )
      overall <- broom::tidy(fit) |>
        dplyr::filter(term == "congenial") |>
        dplyr::transmute(
          contrast = "overall", estimate, std_error = std.error, df,
          conf_low = conf.low, conf_high = conf.high, statistic, p_two_sided = p.value,
          n = nobs(fit), inference = "primary", covariance = "CR2", confidence = .95
        )
      dplyr::bind_rows(overall, fit_contrasts(sample, "gun_rating"))
    }) |>
    dplyr::ungroup()
  list(cells = cells, contrasts = contrasts)
}

summarize_model <- function(fit, label, covariance = "classical", records = NULL) {
  if (covariance == "cr2") {
    robust <- estimatr::lm_robust(formula(fit), data = records, clusters = participant_key, se_type = "CR2")
    result <- broom::tidy(robust)
  } else if (covariance == "hc3") {
    robust <- estimatr::lm_robust(formula(fit), data = model.frame(fit), se_type = "HC3")
    result <- broom::tidy(robust)
  } else {
    result <- broom::tidy(fit)
  }
  names(result) <- gsub("[.]", "_", names(result))
  result |>
    dplyr::rename(p_two_sided = p_value) |>
    dplyr::mutate(
      model = label, covariance = covariance, n = nobs(fit), rank = fit$rank,
      n_columns = ncol(model.matrix(fit)), is_full_rank = rank == n_columns,
      converged = if (inherits(fit, "glm")) fit$converged else TRUE
    )
}
