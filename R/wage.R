read_wage_responses <- function() {
  survey <- read_survey(2)
  linkage <- readr::read_csv(project_file("data", "extracted", "surveys", "respondent_linkage.csv"),
    show_col_types = FALSE
  ) |>
    dplyr::filter(study == 2)
  survey <- survey[linkage$source_row, ]
  answers <- sapply(survey[paste0("cvd", 5:8)], survey_number)
  stopifnot(all(rowSums(!is.na(answers)) == 1))
  tibble::tibble(
    respondent_id = linkage$respondent_id, wage_branch = max.col(!is.na(answers)) + 4L,
    wage_response = rowSums(answers, na.rm = TRUE)
  )
}

reconstruct_wage <- function(records, responses = read_wage_responses()) {
  stopifnot(
    !anyDuplicated(records$respid),
    !anyDuplicated(responses$respondent_id),
    setequal(records$respid, responses$respondent_id),
    all(responses$wage_branch %in% 5:8), all(responses$wage_response %in% 1:2)
  )
  responses <- responses[match(records$respid, responses$respondent_id), ]
  records$prowage <- as.integer(responses$wage_branch %in% c(5, 7))
  records$acc2 <- as.integer(responses$wage_branch %in% c(7, 8))
  records$cvdwage <- as.integer(responses$wage_response == ifelse(records$prowage == 1, 2, 1))
  records$wagecong <- as.integer(records$wage == records$prowage)
  records
}
