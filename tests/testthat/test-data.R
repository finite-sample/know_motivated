testthat::test_that("source bytes and independent formats agree", {
  withr::with_dir(project_root, {
    testthat::expect_silent(verify_sources())
    rebuilt <- read_studies(raw_dir)
    testthat::expect_equal(rebuilt, respondents)
  })
})

testthat::test_that("units, numeracy and congeniality are conserved", {
  testthat::expect_equal(as.integer(table(respondents$study)), c(785L, 947L, 1062L))
  testthat::expect_equal(nrow(tasks), 4803)
  testthat::expect_false(anyDuplicated(respondents$respondent_key) > 0)
  testthat::expect_equal(respondents$numeracy_count, rowSums(respondents[paste0("numeracy_item_", 1:5)]))
  sample <- dplyr::filter(respondents, study < 3)
  testthat::expect_equal(sample$gun_congenial, as.numeric(sample$gun_ban == sample$gun_anti))
  sample <- dplyr::filter(respondents, study == 2)
  testthat::expect_equal(sample$wage_congenial, as.numeric(sample$wage_support == sample$wage_pro))
  testthat::expect_true(all(is.na(respondents$gun_rating[respondents$study == 3])))
  testthat::expect_equal(sum(respondents$study == 1 & !respondents$is_high_numeracy), 0)
})

testthat::test_that("source recovery restores Study 2 and preserves the historical release", {
  sample <- dplyr::filter(respondents, study == 2)
  testthat::expect_equal(sum(sample$wage_correct), 825)
  testthat::expect_equal(mean(sample$wage_correct), 825 / 947)
  released <- dplyr::filter(read_studies(raw_dir, use_survey = FALSE), study == 2)
  testthat::expect_equal(sum(released$wage_correct), 524)
  testthat::expect_equal(sum(sample$wage_correct != released$wage_correct), 301)
  testthat::expect_equal(sum(sample$wage_incentive != released$wage_incentive), 354)
  testthat::expect_equal(sum(sample$wage_pro != released$wage_pro), 354)
  responses <- read_wage_responses()
  branch <- responses$wage_branch[match(sample$respondent_id, responses$respondent_id)]
  testthat::expect_equal(released$wage_incentive, ifelse(branch == 8, 1, released$gun_incentive))
  testthat::expect_equal(released$wage_pro, ifelse(branch == 8, 0, released$gun_anti))
  testthat::expect_equal(
    released$wage_correct,
    as.numeric(sample$wage_correct == 1 & sample$wage_pro == released$wage_pro)
  )
  testthat::expect_equal(nrow(unique(sample[c("gun_anti", "gun_incentive", "wage_pro", "wage_incentive")])), 16)
  testthat::expect_equal(unname(table(released$gun_incentive, released$wage_incentive)),
    matrix(c(355L, 0L, 129L, 463L), 2),
    ignore_attr = TRUE
  )
  models <- readr::read_csv(file.path(table_dir, "model_coefficients.csv"), show_col_types = FALSE)
  model <- dplyr::filter(models, model == "wage_logit_2_1")
  testthat::expect_true(all(model$rank == 16 & model$n_columns == 16 & model$n == 613))
})

testthat::test_that("wage reconstruction uses response keys and questionnaire branches", {
  responses <- read_wage_responses()
  original <- new.env(parent = emptyenv())
  load(file.path(raw_dir, "Study2.RData"), envir = original)
  reference <- reconstruct_wage(original$df2, responses)
  testthat::expect_equal(reconstruct_wage(original$df2, responses[rev(seq_len(nrow(responses))), ]), reference)
  testthat::expect_error(reconstruct_wage(original$df2, responses[-1, ]))
  testthat::expect_error(reconstruct_wage(original$df2, dplyr::bind_rows(responses, responses[1, ])))
  preserved <- setdiff(names(original$df2), c("prowage", "acc2", "cvdwage", "wagecong"))
  testthat::expect_identical(reference[preserved], original$df2[preserved])
  probe <- data.frame(respid = 1:8, wage = rep(c(0, 1), 4))
  items <- data.frame(respondent_id = 1:8, wage_branch = rep(5:8, each = 2), wage_response = rep(1:2, 4))
  reconstructed <- reconstruct_wage(probe, items)
  testthat::expect_equal(reconstructed$cvdwage, c(0L, 1L, 1L, 0L, 0L, 1L, 1L, 0L))
  testthat::expect_equal(reconstructed$acc2, rep(c(0L, 1L), each = 4))
})
