testthat::test_that("corrected ratings are invariant to row order", {
  original <- estimate_ratings(respondents)$contrasts
  withr::local_seed(104)
  shuffled <- estimate_ratings(respondents[sample.int(nrow(respondents)), ])$contrasts
  testthat::expect_equal(original, shuffled, tolerance = 1e-10)
})

testthat::test_that("contrast definitions recover planted factorial effects", {
  simulated <- expand.grid(congenial = 0:1, incentive = 0:1, replicate = 1:20)
  simulated$noise <- rep(c(-.1, .1), each = 4, length.out = nrow(simulated))
  simulated$correct <- with(simulated, 2 + .4 * congenial + .7 * incentive - .3 * congenial * incentive + noise)
  result <- fit_contrasts(simulated)
  testthat::expect_equal(result$estimate, c(.4, .1, -.3, .7, .4), tolerance = 1e-10)
})

testthat::test_that("HC2 cell inference agrees with the standard one-sample t test", {
  sample <- dplyr::filter(respondents, study == 1, gun_ban == 0, gun_congenial == 0, gun_incentive == 0)
  cells <- summarize_cells(sample, "study", "gun_rating", method = "hc2")
  reference <- t.test(sample$gun_rating)
  testthat::expect_equal(cells$std_error, reference$stderr, tolerance = 1e-10)
  testthat::expect_equal(c(cells$conf_low, cells$conf_high), as.numeric(reference$conf.int), tolerance = 1e-10)
})

testthat::test_that("the wage task uses its own treatment denominators", {
  cells <- readr::read_csv(file.path(table_dir, "accuracy_cells.csv"), show_col_types = FALSE) |>
    dplyr::filter(exhibit == "figure_si_7") |>
    dplyr::arrange(incentive, congenial)
  testthat::expect_equal(cells$n, c(174, 192, 184, 159))
})

testthat::test_that("worldview coding includes people with known worldview and missing policy attitude", {
  sample <- make_exhibit_samples(respondents, tasks)$figure_si_4 |>
    dplyr::filter(!is.na(position_label))
  testthat::expect_equal(as.integer(table(sample$position_label)), c(199L, 701L))
  testthat::expect_equal(
    sum(sample$congenial == 1, na.rm = TRUE),
    sum(
      sample$position_label == "Liberal Democrat" &
        respondents$gun_anti[match(sample$respondent_key, respondents$respondent_key)] == 1,
      na.rm = TRUE
    ) +
      sum(
        sample$position_label == "Conservative Republican" &
          respondents$gun_anti[match(sample$respondent_key, respondents$respondent_key)] == 0,
        na.rm = TRUE
      )
  )
})

testthat::test_that("overall rating denominators come from the fitted sample", {
  estimates <- estimate_ratings(respondents)$contrasts |>
    dplyr::filter(contrast == "overall") |>
    dplyr::arrange(position_label)
  testthat::expect_equal(estimates$n, c(453L, 830L))
})

testthat::test_that("numeracy subgroup incentive contrasts retain their condition labels", {
  effects <- readr::read_csv(file.path(table_dir, "numeracy_incentive_effects.csv"), show_col_types = FALSE)
  testthat::expect_true(all(effects$contrast[effects$congenial == 1] == "incentive_congenial"))
  testthat::expect_true(all(effects$contrast[effects$congenial == 0] == "incentive_uncongenial"))
})

testthat::test_that("primary inference uses contrast-specific worker-cluster degrees of freedom", {
  results <- readr::read_csv(file.path(table_dir, "accuracy_contrasts.csv"), show_col_types = FALSE)
  selected <- dplyr::filter(
    results, exhibit == "figure_2", position_label == "Carry opponents",
    inference == "primary", contrast == "congeniality_incentive"
  )
  testthat::expect_equal(selected$covariance, "CR2")
  testthat::expect_equal(selected$df, 201.7807, tolerance = 1e-5)
  testthat::expect_equal(selected$p_two_sided, .6203747, tolerance = 1e-6)
  study_two <- dplyr::filter(respondents, study == 2)
  testthat::expect_equal(dplyr::n_distinct(study_two$participant_key), 947L)
})
