survey_number <- function(values) suppressWarnings(as.numeric(values))

reconstruct_survey <- function(records, study, correct_coding = FALSE) {
  number <- function(column) survey_number(records[[column]])
  n <- nrow(records)
  result <- data.frame(study = rep(study, n))
  keys <- if (study == 1) c(500, 10, 20, 100, .1) else c(500, 10, 100, 20, .1)
  for (i in 1:5) result[[paste0("num", i)]] <- as.integer(number(paste0("num", i)) %in% keys[i])
  if (study < 3 && !correct_coding) result$num5 <- as.integer(records$num5 %in% c(".1", ".10", "0.1"))
  result$numeracy <- rowSums(result[paste0("num", 1:5)])
  result$fem <- number("sex") - 1
  age_year <- if (correct_coding) number("interview_year") else if (study == 3) 2016 else 2014
  result$age <- age_year - number("yob")
  result$agecat <- as.character(cut(result$age, c(17, 29, 44, 64, Inf),
    labels = c("18-29", "30-44", "45-64", "65 or older")
  ))
  result$edu <- c("HS or Less", "HS or Less", "Some College", "College Degree", "Post-Graduate")[number("edu")]
  races <- sapply(paste0("race_", 1:6), function(column) number(column) %in% 1)
  ethnicity <- rep(NA_character_, n)
  non_hispanic <- number("hisp") %in% 2
  ethnicity[non_hispanic & races[, 1]] <- "White, Non-Hisp"
  ethnicity[non_hispanic & races[, 2]] <- "Black, Non-Hisp"
  ethnicity[non_hispanic & races[, 4]] <- "Asian, Non-Hisp"
  ethnicity[non_hispanic & rowSums(races[, c(3, 5, 6), drop = FALSE]) > 0] <- "Other, Non-Hisp"
  ethnicity[number("hisp") %in% 1] <- "Hispanic/Latino"
  ethnicity[rowSums(races) > 1] <- "Mixed"
  result$raceeth <- ethnicity
  party <- number("pid")
  strength <- number("pidstr")
  lean <- number("pidlean")
  other_codes <- if (correct_coding) c(5, 3, 4) else c(3, 5, 4)
  result$pid7 <- ifelse(party == 1, 8 - strength,
    ifelse(party == 2, strength,
      ifelse(party == 3, c(5, 3, 4)[lean], ifelse(party == 4, other_codes[lean], NA_real_))
    )
  )
  ideology <- number("ideo")
  result$ideo5 <- ifelse(ideology == 1, number("ideolib"),
    ifelse(ideology == 2, 3, ifelse(ideology == 3, 6 - number("ideocon"), NA_real_))
  )
  position <- function(column) ifelse(number(column) %in% 1:2, as.numeric(number(column) == 1), NA_real_)
  result$ban <- position("ban")
  result$banimp <- (if (study == 3) 6 else 5) - number("banimp")
  result$owngun <- position("gunown")
  task <- function(branches) {
    answers <- sapply(paste0("cvd", branches), number)
    observed <- !is.na(answers)
    assignment <- if (study < 3) {
      sapply(paste0("intro", branches), function(column) number(column) %in% 1)
    } else {
      observed
    }
    stopifnot(all(rowSums(observed) <= 1), all(rowSums(assignment) <= 1))
    index <- max.col(assignment, ties.method = "first")
    index[rowSums(assignment) == 0] <- NA_integer_
    branch <- branches[index]
    answer <- answers[cbind(seq_len(n), index)]
    correct_option <- c(1, 2, 1, 2, 2, 1, 2, 1)[branch]
    correct <- as.integer(answer == correct_option)
    if (study < 3) correct[!is.na(branch) & is.na(answer)] <- 0L
    list(branch = branch, answer = answer, correct = correct)
  }
  gun <- task(1:4)
  indicator <- function(branch, values) ifelse(is.na(branch), NA_real_, as.numeric(branch %in% values))
  direction <- indicator(gun$branch, c(1, 3))
  if (study < 3) result$antigun <- direction
  result$guncong <- as.numeric(result$ban == direction)
  result$acc <- indicator(gun$branch, c(3, 4))
  result$cvd <- gun$correct
  if (study < 3) {
    result$well <- number("ratewell_1") - 1
    result$conv <- number("rateconv_1") - 1
  }
  if (study == 1) {
    for (i in 1:4) {
      first <- number(paste0("recalldem_", i, "_text"))
      second <- number(paste0("recallcon_", i, "_text"))
      result[[paste0("rec_", letters[i])]] <- ifelse(is.na(first), second, first)
    }
  } else {
    result$wage <- position("wage")
    result$wageimp <- (if (study == 3) 6 else 5) - number("wageimp")
    wage <- task(5:8)
    direction <- indicator(wage$branch, c(5, 7))
    if (study == 2) result$prowage <- direction
    result$wagecong <- as.numeric(result$wage == direction)
    result$acc2 <- indicator(wage$branch, c(7, 8))
    result$cvdwage <- wage$correct
    if (study == 3) {
      confidence <- function(branches) {
        values <- sapply(paste0("conf", branches), number)
        stopifnot(all(rowSums(!is.na(values)) <= 1))
        ifelse(rowSums(!is.na(values)) == 0, NA_real_, rowSums(values, na.rm = TRUE))
      }
      result$conf <- confidence(1:4)
      result$confwage <- confidence(5:8)
    }
  }
  result
}

survey_inclusion <- function(records, study) {
  country <- records$condition %in% "United States"
  if (study == 1) {
    entered <- rowSums(!is.na(records[paste0("intro", 1:4)])) > 0
    return(country & !is.na(records$workerid) & entered)
  }
  if (study == 2) {
    answered_gun <- rowSums(!is.na(records[paste0("cvd", 1:4)])) == 1
    answered_wage <- rowSums(!is.na(records[paste0("cvd", 5:8)])) == 1
    return(answered_gun & answered_wage)
  }
  country
}

link_survey <- function(records, released, study) {
  included <- survey_inclusion(records, study)
  reconstructed <- reconstruct_survey(records, study)[included, ]
  columns <- setdiff(names(released), c("respid", if (study == 2) c("prowage", "wagecong", "acc2", "cvdwage")))
  key <- function(values) do.call(paste, c(lapply(values, as.character), sep = "|"))
  source_keys <- key(reconstructed[columns])
  released_keys <- key(released[columns])
  stopifnot(identical(sort(source_keys), sort(released_keys)))
  index <- integer(nrow(released))
  for (value in unique(released_keys)) index[which(released_keys == value)] <- which(source_keys == value)
  stopifnot(!anyDuplicated(index))
  tibble::tibble(
    study = study, respondent_id = released$respid, source_row = which(included)[index],
    linkage = ifelse(duplicated(released_keys) | duplicated(released_keys, fromLast = TRUE),
      "identical_released_profiles", "unique_profile"
    )
  )
}

read_survey <- function(study) {
  readr::read_csv(project_file("data", "extracted", "surveys", paste0("study_", study, ".csv")),
    col_types = readr::cols(.default = readr::col_character()), na = c("", "NA"), name_repair = "minimal"
  )
}
