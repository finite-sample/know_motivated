testthat::test_that("full exports reconstruct every released field before documented corrections", {
  linkage <- readr::read_csv(project_file("data", "extracted", "surveys", "respondent_linkage.csv"),
    show_col_types = FALSE
  )
  for (study in 1:3) {
    survey <- read_survey(study)
    testthat::expect_equal(nrow(survey), c(1278L, 1456L, 1067L)[study])
    testthat::expect_equal(sum(survey_inclusion(survey, study)), c(785L, 947L, 1062L)[study])
    index <- linkage[linkage$study == study, ]
    original <- new.env(parent = emptyenv())
    load(file.path(raw_dir, paste0("Study", study, ".RData")), envir = original)
    original <- original[[paste0("df", study)]]
    index <- index[match(original$respid, index$respondent_id), ]
    reconstructed <- reconstruct_survey(survey[index$source_row, ], study)
    columns <- setdiff(names(original), c("respid", if (study == 2) c("prowage", "wagecong", "acc2", "cvdwage")))
    for (column in columns) {
      expected <- original[[column]]
      if (is.factor(expected)) expected <- as.character(expected)
      testthat::expect_equal(reconstructed[[column]], expected, ignore_attr = TRUE, info = paste(study, column))
    }
  }
  testthat::expect_equal(sum(linkage$linkage == "identical_released_profiles"), 3)
})

testthat::test_that("raw scoring fixes and repeated records remain explicit", {
  historical <- read_studies(raw_dir, correct_coding = FALSE)
  for (study in 1:3) {
    selected <- respondents$study == study
    testthat::expect_equal(
      sum(respondents$numeracy_count[selected] != historical$numeracy_count[selected]),
      c(4L, 9L, 0L)[study]
    )
    testthat::expect_equal(
      sum(respondents$party_id[selected] != historical$party_id[selected], na.rm = TRUE),
      c(15L, 10L, 5L)[study]
    )
  }
  study_one <- dplyr::filter(respondents, study == 1)
  testthat::expect_equal(length(unique(study_one$participant_key)), 749)
  testthat::expect_equal(sum(study_one$is_gun_answer_missing), 2)
  testthat::expect_true(all(study_one$gun_correct[study_one$is_gun_answer_missing] == 0))
})

testthat::test_that("research exports contain pseudonyms instead of direct identifiers", {
  paths <- list.files(project_file("data", "extracted"), pattern = "[.]csv$", recursive = TRUE, full.names = TRUE)
  aliases <- c(
    v1 = "response", responseid = "response", workerid = "worker", assignmentid = "assignment",
    psid = "panel", rid = "panel_response", risn = "panel_serial", custom1 = "panel_custom"
  )
  for (path in paths) {
    records <- readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()), na = c("", "NA"))
    testthat::expect_false(any(grepl("^browser|^ipaddress$|^ip_address$|^comments$|^recipient", names(records))))
    for (column in intersect(names(records), names(aliases))) {
      observed <- records[[column]][!is.na(records[[column]])]
      testthat::expect_true(all(grepl(paste0("^", aliases[[column]], "_[0-9]{6}$"), observed)))
    }
  }
})

testthat::test_that("ages use interview years while historical comparisons retain the released anchor", {
  historical <- read_studies(raw_dir, correct_coding = FALSE)
  for (study in 1:3) {
    selected <- respondents$study == study
    testthat::expect_equal(
      sum(respondents$age_years[selected] != historical$age_years[selected], na.rm = TRUE),
      c(281L, 946L, 0L)[study]
    )
    testthat::expect_equal(
      sum(respondents$age_group[selected] != historical$age_group[selected], na.rm = TRUE),
      c(13L, 62L, 0L)[study]
    )
  }
})

testthat::test_that("reported-answer tables exclude unanswered items", {
  response <- readr::read_csv(file.path(table_dir, "response_bias.csv"), show_col_types = FALSE)
  supporters <- dplyr::filter(
    response, sample == "pooled_1_2", position_label == "Carry supporters",
    incentive == 0, congenial == 0
  )
  opponents <- dplyr::filter(
    response, sample == "pooled_1_2", position_label == "Carry opponents",
    incentive == 0, congenial == 1
  )
  testthat::expect_equal(c(supporters$n_congenial, supporters$n), c(123, 215))
  testthat::expect_equal(c(opponents$n_congenial, opponents$n), c(71, 127))
})

testthat::test_that("first-participation sensitivity retains one chronological eligible record per worker", {
  first <- dplyr::filter(respondents, study == 1, worker_attempt == 1)
  testthat::expect_equal(nrow(first), 749L)
  testthat::expect_equal(dplyr::n_distinct(first$participant_key), 749L)
  repeated <- dplyr::filter(respondents, study == 1) |>
    dplyr::group_by(participant_key) |>
    dplyr::summarise(valid_order = identical(sort(worker_attempt), seq_len(dplyr::n())), .groups = "drop")
  testthat::expect_true(all(repeated$valid_order))
})
