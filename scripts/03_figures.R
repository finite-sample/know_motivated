cells <- readr::read_csv(file.path(table_dir, "accuracy_cells.csv"), show_col_types = FALSE)
contrasts <- readr::read_csv(file.path(table_dir, "accuracy_contrasts.csv"), show_col_types = FALSE)
for (name in unique(cells$exhibit)) {
  save_figure(plot_accuracy(dplyr::filter(cells, exhibit == name), name), name)
  selected <- contrasts |>
    dplyr::filter(exhibit == name) |>
    dplyr::mutate(dplyr::across(c(estimate, conf_low, conf_high), ~ .x * 100))
  save_figure(plot_contrasts(
    selected, paste0(exhibit_titles[name], ": contrasts"),
    "Difference in correct answers (percentage points)",
    archive_warning = name %in% c("figure_4", "figure_si_7")
  ), paste0(name, "_contrasts"))
}
ratings <- readr::read_csv(file.path(table_dir, "rating_contrasts.csv"), show_col_types = FALSE)
save_figure(plot_contrasts(ratings, "Figure 5: credibility ratings", "Difference in rating (0-10 scale)"), "figure_5")
flows <- readr::read_csv(file.path(table_dir, "participant_flow.csv"), show_col_types = FALSE)
for (study_id in 1:3) {
  display <- flows |>
    dplyr::filter(study == study_id) |>
    dplyr::group_by(study) |>
    dplyr::summarise(dplyr::across(c(n_archived, n_position, n_supporters, n_opponents, n_outcome), sum)) |>
    tidyr::pivot_longer(-study, names_to = "stage", values_to = "n")
  survey <- read_survey(study_id)
  display <- dplyr::bind_rows(
    tibble::tibble(study = study_id, stage = "n_source", n = nrow(survey)), display
  )
  labels <- c(n_source = "Full source export", flow_labels)
  display$stage <- factor(display$stage, rev(names(labels)), rev(unname(labels)))
  plot <- ggplot2::ggplot(display, ggplot2::aes(n, stage)) +
    ggplot2::geom_col(fill = "#08519c") +
    ggplot2::geom_text(ggplot2::aes(label = n), hjust = -.2) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, .12))) +
    ggplot2::labs(
      x = "Survey records", y = NULL, title = paste("Study", study_id, "source and analysis counts"),
      caption = paste("Counts overlap; not sequential exclusions.",
        "Source exports include records excluded from the released sample.",
        sep = "\n"
      )
    ) +
    theme_paper()
  save_figure(plot, paste0("figure_si_", study_id), height = 4)
}
