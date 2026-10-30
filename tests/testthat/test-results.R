testthat::test_that("main carry results reproduce reported precision", {
  results <- readr::read_csv(file.path(table_dir, "published_accuracy_comparison.csv"), show_col_types = FALSE)
  testthat::expect_true(all(results$agrees_at_printed_precision[results$exhibit %in% c("figure_2", "figure_3")]))
  testthat::expect_true(all(results$agrees_at_printed_precision))
  contrasts <- readr::read_csv(file.path(table_dir, "replication_accuracy_contrasts.csv"), show_col_types = FALSE)
  selected <- dplyr::filter(
    contrasts, exhibit == "figure_2", position_label == "Carry opponents",
    contrast == "interaction", inference == "hc0_normal"
  )
  original <- run_original("fig2")
  testthat::expect_equal(selected$estimate, original$diff.opp[3] / 100, tolerance = 1e-10)
  testthat::expect_equal(selected$std_error, original$se.diff.opp[3] / 100, tolerance = 1e-10)
})

testthat::test_that("recovered wage graphs match the original scripts and publication", {
  results <- readr::read_csv(file.path(table_dir, "published_accuracy_comparison.csv"), show_col_types = FALSE)
  control <- dplyr::filter(results, exhibit == "figure_si_8")
  testthat::expect_equal(nrow(control), 8L)
  testthat::expect_true(all(control$agrees_at_printed_precision))
  for (spec in list(c("figure_si_7", "fig.si7"), c("figure_si_8", "fig.si8"), c("figure_4", "fig4"))) {
    original <- run_original(spec[2], recover_wage = TRUE)
    for (group in c("sup", "opp")) {
      historical <- original[[paste0("cvd.", group)]]
      if (is.null(historical)) next
      selected <- results |>
        dplyr::filter(
          exhibit == spec[1], position_label == ifelse(group == "sup", "Wage supporters", "Wage opponents")
        ) |>
        dplyr::arrange(incentive, congenial)
      testthat::expect_equal(selected$reproduced_pct, historical, tolerance = 1e-10)
    }
  }
})

testthat::test_that("confidence shares use observed joint denominators", {
  counts <- readr::read_csv(file.path(table_dir, "confidence_joint.csv"), show_col_types = FALSE)
  sums <- counts |>
    dplyr::group_by(task, incentive) |>
    dplyr::summarise(share = sum(share), n = sum(n), denominator = dplyr::first(denominator), .groups = "drop")
  testthat::expect_equal(sums$share, rep(1, 4))
  testthat::expect_equal(sums$n, sums$denominator)
})

testthat::test_that("all requested numerical figures and supplementary outputs exist", {
  names <- c(paste0("figure_", 2:5), paste0("figure_si_", 1:8))
  for (name in names) {
    for (extension in c("png", "pdf")) {
      testthat::expect_gt(file.info(file.path(figure_dir, paste0(name, ".", extension)))$size, 1000)
    }
  }
  coefficients <- readr::read_csv(file.path(table_dir, "model_coefficients.csv"), show_col_types = FALSE)
  testthat::expect_true(all(coefficients$converged))
  testthat::expect_true(all(coefficients$is_full_rank))
})
