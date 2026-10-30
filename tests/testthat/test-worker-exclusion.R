testthat::test_that("exclusion removes every record from repeated Study 1 IDs before subgroup selection", {
  retained <- exclude_repeated_workers(respondents)
  study_one <- dplyr::filter(retained, study == 1)
  testthat::expect_equal(nrow(study_one), 715L)
  testthat::expect_equal(dplyr::n_distinct(study_one$participant_key), 715L)
  testthat::expect_equal(dplyr::filter(retained, study != 1), dplyr::filter(respondents, study != 1))
  excluded <- dplyr::filter(respondents, !respondent_key %in% retained$respondent_key)
  testthat::expect_equal(nrow(excluded), 70L)
  testthat::expect_equal(dplyr::n_distinct(excluded$participant_key), 34L)
  testthat::expect_false(any(excluded$participant_key %in% study_one$participant_key))
  fixture <- tibble::tibble(
    study = c(1L, 1L, 1L, 2L), has_worker_id = c(TRUE, TRUE, TRUE, FALSE),
    participant_key = c("worker_a", "worker_a", "worker_b", "worker_a"), gun_ban = c(NA, 1, 0, 1)
  )
  testthat::expect_equal(exclude_repeated_workers(fixture), fixture[3:4, ])
})

testthat::test_that("exclusion contrasts agree with direct package fits and the existing sensitivity", {
  results <- readr::read_csv(file.path(table_dir, "worker_exclusion_summary.csv"), show_col_types = FALSE)
  selected <- dplyr::filter(
    results, exhibit == "figure_2", position_label == "Carry opponents", specification == "exclude_repeated_workers"
  )
  sample <- exclude_repeated_workers(respondents) |>
    dplyr::filter(study == 1 | (study == 2 & is_high_numeracy), gun_ban == 1)
  fit <- estimatr::lm_robust(gun_correct ~ gun_congenial * gun_incentive,
    data = sample, clusters = participant_key, se_type = "CR2"
  )
  reference <- broom::tidy(fit) |>
    dplyr::filter(term == "gun_congenial:gun_incentive")
  testthat::expect_equal(selected$estimate, 100 * reference$estimate, tolerance = 1e-10)
  testthat::expect_equal(selected$p_two_sided, reference$p.value, tolerance = 1e-10)
  testthat::expect_equal(selected$n, 437L)
  sensitivity <- readr::read_csv(file.path(table_dir, "source_coding_sensitivity.csv"), show_col_types = FALSE) |>
    dplyr::filter(specification == "exclude_repeated_workers", outcome == "gun_correct", position == 1)
  testthat::expect_equal(selected$estimate, 100 * sensitivity$estimate, tolerance = 1e-10)
  testthat::expect_equal(selected$p_two_sided, sensitivity$p_value, tolerance = 1e-10)
})
