format_p_value <- function(value) {
  ifelse(is.na(value), "--", ifelse(value < .001, "<0.001", sprintf("%.3f", value)))
}

write_latex_table <- function(records, name, title, note) {
  labels <- c(
    table_si_1 = "sample", table_si_2 = "balance", table_si_3 = "spillover",
    table_si_4 = "accnum", table_si_5 = "recalla", table_si_6 = "recallc", table_si_7 = "logit1",
    table_si_8 = "logit2", table_si_9 = "demand_opp", table_si_10 = "demand_supp", table_si_11 = "confidence"
  )
  table <- knitr::kable(records,
    format = "latex", booktabs = TRUE, longtable = TRUE, escape = TRUE, linesep = "",
    caption = title, label = if (name %in% names(labels)) labels[[name]] else NULL, row.names = FALSE
  )
  table_lines <- strsplit(as.character(table), "\n", fixed = TRUE)[[1]]
  header_end <- which(table_lines == "\\midrule")[1]
  table_lines <- append(
    table_lines,
    c("\\endfirsthead", "\\toprule", table_lines[header_end - 1], "\\midrule", "\\endhead"),
    after = header_end
  )
  writeLines(
    c(table_lines, paste0("\\noindent\\footnotesize ", note, "\\par\\normalsize")),
    file.path(table_dir, paste0(name, ".tex"))
  )
}

write_publication_tables <- function() {
  read <- function(name) readr::read_csv(file.path(table_dir, paste0(name, ".csv")), show_col_types = FALSE)
  sample_labels <- c(
    study_1 = "Study 1", study_2 = "Study 2", study_2_high = "Study 2: high",
    study_3 = "Study 3", study_3_high = "Study 3: high"
  )
  trait_labels <- c(
    party_group = "Party", ideology_group = "Ideology", education = "Education",
    age_group = "Age", is_female = "Sex", race_ethnicity = "Race/ethnicity"
  )
  traits <- read("sample_characteristics") |>
    dplyr::filter(!is.na(category)) |>
    dplyr::mutate(
      category = ifelse(variable == "is_female", ifelse(category == "1", "Female", "Male"), category),
      variable = unname(trait_labels[variable]), sample = unname(sample_labels[sample]),
      value = sprintf("%.1f (%d)", 100 * share, n)
    ) |>
    dplyr::select(variable, category, sample, value) |>
    tidyr::pivot_wider(names_from = sample, values_from = value)
  names(traits)[1:2] <- c("Characteristic", "Category")
  write_latex_table(
    traits, "table_si_1", "Sample characteristics",
    "Percent of nonmissing responses, with counts in parentheses. High numeracy means at least four correct items."
  )
  balance <- read("balance_tests") |>
    dplyr::transmute(
      Study = study, Outcome = gsub("_", " ", outcome), N = n,
      F = round(f_statistic, 2), df1 = df_numerator, df2 = df_denominator, p = format_p_value(p_value)
    )
  write_latex_table(
    balance, "table_si_2", "Covariate balance",
    paste(
      "Classical F tests. Studies 1 and 2 use policy-congeniality factorials except race, which uses incentives alone.",
      "Study 3 uses incentives alone. Alternative race specifications are in race\\_balance\\_checks.csv."
    )
  )
  models <- read("model_coefficients")
  model_table <- function(pattern, name, title) {
    selected <- models |>
      dplyr::filter(grepl(pattern, model)) |>
      dplyr::transmute(
        Model = model, Term = term, Covariance = covariance, Estimate = round(estimate, 3),
        SE = round(std_error, 3), p = format_p_value(p_two_sided), N = n
      )
    if (grepl("logit", pattern)) {
      selected$OR <- round(exp(models$estimate[grepl(pattern, models$model)]), 3)
    }
    replacements <- c(
      gun_congenial = "GC", gun_incentive = "GI", wage_congenial = "WC", wage_incentive = "WI",
      wage_logit_ = "Wage ", gun_logit_position_ = "Gun ", recall_ = "Recall ", "(Intercept)" = "Intercept"
    )
    for (old in names(replacements)) {
      selected$Term <- gsub(old, replacements[[old]], selected$Term, fixed = TRUE)
      selected$Model <- gsub(old, replacements[[old]], selected$Model, fixed = TRUE)
    }
    selected$Model <- gsub("_", ":", selected$Model)
    model_note <- if (grepl("wage_logit", pattern)) {
      paste(
        "GC/GI: gun congeniality/incentive; WC/WI: wage congeniality/incentive.",
        "Models identify study and wage support (1=yes). Coefficients are log odds; OR: odds ratio."
      )
    } else if (grepl("gun_logit", pattern)) {
      "GC/GI: gun congeniality/incentive. Model: ban support (1=yes). Coefficients: log odds; OR: odds ratio."
    } else {
      "GC/GI: gun congeniality/incentive. Coefficients are recalled counts. Covariance identifies the inference method."
    }
    write_latex_table(
      selected, name, title, paste(model_note, "Colons denote interactions. N is the fitted complete-case sample.")
    )
  }
  model_table("^wage_logit", "table_si_3", "Wage correctness and cross-task assignments")
  numeracy <- read("numeracy_incentive_effects") |>
    dplyr::filter(study %in% 2:3 | (study == 1 & numeracy_group == "high")) |>
    dplyr::transmute(
      Study = study, Numeracy = numeracy_group, Group = position_label,
      Congenial = congenial, Effect = round(100 * estimate, 2),
      `95% interval` = sprintf("[%.2f, %.2f]", 100 * conf_low, 100 * conf_high),
      p = format_p_value(p_two_sided), N = n
    )
  write_latex_table(
    numeracy, "table_si_4", "Incentive effects by numeracy and congeniality",
    paste(
      "Effects are percentage points. Two-sided 95\\% t intervals; Study 1 worker CR2, otherwise HC2.",
      "High numeracy: at least four correct items."
    )
  )
  model_table("^recall_a$", "table_si_5", "Recall of stimulus cell A")
  model_table("^recall_c$", "table_si_6", "Recall of stimulus cell C")
  model_table("^gun_logit_position_0$", "table_si_7", "Gun correctness: carry supporters")
  model_table("^gun_logit_position_1$", "table_si_8", "Gun correctness: carry opponents")
  response <- read("response_bias")
  for (position in c("Carry supporters", "Carry opponents")) {
    selected <- response |>
      dplyr::filter(position_label == position, sample == "pooled_1_2") |>
      dplyr::transmute(
        Sample = gsub("_", " ", sample), Incentive = incentive, Congenial = congenial,
        `Congenial answer (%)` = round(100 * congenial_share, 1), Odds = round(response_odds, 2), N = n
      )
    name <- if (position == "Carry opponents") "table_si_9" else "table_si_10"
    write_latex_table(
      selected, name, paste("Reported answer direction:", tolower(position)),
      "Shares are within the specified treatment cell. Odds are congenial answers divided by uncongenial answers."
    )
  }
  confidence <- read("confidence_joint") |>
    dplyr::filter(incentive == 0) |>
    dplyr::transmute(
      Task = task, Confidence = confidence, Correct = correct, Count = n,
      `Joint share (%)` = round(100 * share, 1), Denominator = denominator
    )
  write_latex_table(
    confidence, "table_si_11", "Confidence and correctness without incentives",
    "Study 3. Confidence ranges from 1 (not confident at all) to 5 (certain). Joint shares sum to 100\\% within task."
  )
  contrasts <- read("accuracy_contrasts") |>
    dplyr::filter(
      exhibit %in% c("figure_2", "figure_3", "figure_4"), inference == "primary",
      contrast == "interaction" | exhibit == "figure_3"
    ) |>
    dplyr::transmute(
      Figure = sub("figure_", "", exhibit), Group = position_label,
      Effect = round(100 * estimate, 2), `95% interval` = sprintf("[%.2f, %.2f]", 100 * conf_low, 100 * conf_high),
      p = format_p_value(p_two_sided), N = n
    )
  write_latex_table(
    contrasts, "main_contrasts", "Main correctness contrasts",
    paste(
      "Percentage points. Figures 2/4: incentive-by-congeniality interaction; Figure 3: incentive effect.",
      "Corrected coding; two-sided t inference, Study 1 worker CR2, otherwise HC2.",
      "Historical coding: replication\\_accuracy\\_contrasts.csv."
    )
  )
  sensitivity <- read("source_coding_sensitivity") |>
    dplyr::transmute(
      Specification = gsub("_", " ", specification), Outcome = sub("gun_", "", outcome),
      Ban = position, Effect = round(estimate, 3), SE = round(std_error, 3), p = format_p_value(p_value), N = n
    )
  write_latex_table(
    sensitivity, "coding_sensitivity", "Coding and repeated-participant checks",
    paste(
      "Correctness is on a 0--1 scale; ratings on a 0--10 scale. Effects are incentive-by-congeniality interactions.",
      "Worker clusters use estimatr CR2 with coefficient-specific degrees of freedom.",
      "Study 2 worker IDs are unavailable.",
      "Observed answers excludes the two unanswered Study 1 gun items. First participation retains each worker once.",
      "Exclude repeated workers removes every record of a repeated Study 1 ID. Ban=1 denotes carry opponents."
    )
  )
  names <- c("main_contrasts", paste0("table_si_", 1:11), "coding_sensitivity")
  labels <- c("A1", paste0("SI", 1:11), "A2")
  preview <- c(
    "\\documentclass[10pt]{article}", "\\usepackage[margin=0.65in]{geometry}",
    "\\usepackage{fontspec,booktabs,longtable}",
    "\\setmainfont{lmroman10-regular.otf}[BoldFont=lmroman10-bold.otf,ItalicFont=lmroman10-italic.otf]",
    "\\setlength{\\tabcolsep}{4pt}", "\\begin{document}", "\\small",
    unlist(lapply(seq_along(names), function(i) {
      c(
        paste0("\\renewcommand{\\thetable}{", labels[i], "}"),
        paste0("\\input{", names[i], ".tex}"), "\\clearpage"
      )
    })),
    "\\end{document}"
  )
  writeLines(preview, file.path(table_dir, "preview.tex"))
}
