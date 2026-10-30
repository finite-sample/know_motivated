save_figure <- function(plot, name, height = figure_height) {
  for (extension in c("pdf", "png")) {
    ggplot2::ggsave(file.path(figure_dir, paste0(name, ".", extension)), plot,
      width = figure_width, height = height, dpi = figure_dpi, bg = "white"
    )
  }
}

plot_wage_replication <- function(comparison) {
  panels <- c(
    "figure_si_7" = "Study 2 (SI7)", "figure_si_8" = "Study 3 (SI8)",
    "figure_4" = "Studies 2 + 3 (Figure 4)"
  )
  display <- comparison |>
    dplyr::filter(exhibit %in% names(panels)) |>
    dplyr::mutate(
      panel = factor(exhibit, names(panels), unname(panels)),
      condition = factor(
        congenial + 2 * incentive, 0:3,
        c(
          "No incentive: uncongenial", "No incentive: congenial",
          "Incentive: uncongenial", "Incentive: congenial"
        )
      )
    ) |>
    tidyr::pivot_longer(c(published_pct, dataverse_pct, reproduced_pct), names_to = "origin", values_to = "percent") |>
    dplyr::mutate(
      label = ifelse(origin == "published_pct", sprintf("%.1f", percent), sprintf("%.2f", percent)),
      origin = factor(
        origin, c("published_pct", "dataverse_pct", "reproduced_pct"),
        c("Published", "Dataverse V1", "Recovered")
      )
    )
  ggplot2::ggplot(display, ggplot2::aes(percent, condition, colour = origin, shape = origin)) +
    ggplot2::geom_point(position = ggplot2::position_dodge(width = .65), size = 2) +
    ggplot2::geom_text(ggplot2::aes(label = label),
      position = ggplot2::position_dodge(width = .65), hjust = -.3, size = 3, show.legend = FALSE
    ) +
    ggplot2::facet_grid(position_label ~ panel) +
    ggplot2::scale_colour_manual(values = c("#333333", "#a63603", "#08519c")) +
    ggplot2::scale_shape_manual(values = c(17, 4, 16)) +
    ggplot2::scale_x_continuous(limits = c(0, 108), breaks = c(0, 50, 100)) +
    ggplot2::scale_y_discrete(limits = rev) +
    ggplot2::labs(
      x = "Correct answers (%)", y = NULL, colour = NULL, shape = NULL,
      title = "Wage results: publication, Dataverse release, and recovered responses",
      subtitle = "Recovered Study 2 responses reproduce the published graphs.",
      caption = paste(
        "Point estimates only. Published labels checked against journal Figure 4 and supplement Figures 7-8.",
        "SI7 reports supporters only; its opponents panel is intentionally empty.",
        sep = "\n"
      )
    ) +
    theme_paper()
}

plot_accuracy <- function(cells, exhibit) {
  display <- cells |>
    dplyr::mutate(
      incentive = factor(incentive, 0:1, incentive_labels),
      congenial = factor(congenial, 0:1, condition_labels)
    )
  note <- if (exhibit %in% c("figure_4", "figure_si_7")) {
    "Study 2 wage fields reconstructed from original responses. 95% t intervals; worker CR2 for Study 1, HC2 otherwise."
  } else {
    "Corrected responses. 95% t intervals; worker CR2 for Study 1, HC2 otherwise."
  }
  ggplot2::ggplot(display, ggplot2::aes(incentive, 100 * estimate, colour = congenial)) +
    ggplot2::geom_pointrange(ggplot2::aes(ymin = 100 * conf_low, ymax = 100 * conf_high),
      position = ggplot2::position_dodge(width = .35)
    ) +
    ggplot2::geom_text(ggplot2::aes(y = 100 * conf_high, label = paste0("n=", n)),
      position = ggplot2::position_dodge(width = .35), vjust = -.7, size = 3, show.legend = FALSE
    ) +
    ggplot2::facet_wrap(~position_label) +
    ggplot2::scale_colour_manual(values = condition_colours, drop = FALSE) +
    ggplot2::scale_y_continuous(limits = c(0, 108), breaks = seq(0, 100, 20)) +
    ggplot2::labs(
      x = NULL, y = "Correct answers (%)", colour = NULL, caption = note,
      title = unname(exhibit_titles[exhibit])
    ) +
    theme_paper()
}

plot_contrasts <- function(contrasts, title, outcome_label, archive_warning = FALSE) {
  labels <- c(
    overall = "Overall congeniality", congeniality_no_incentive = "Congeniality: no incentive",
    congeniality_incentive = "Congeniality: incentive", interaction = "Incentive x congeniality",
    incentive_uncongenial = "Incentive: uncongenial", incentive_congenial = "Incentive: congenial"
  )
  caption <- "95% t intervals; worker CR2 for Study 1, HC2 otherwise. No multiplicity adjustment."
  if (archive_warning) {
    caption <- paste(
      "Study 2 wage fields reconstructed from original responses.", caption,
      sep = "\n"
    )
  }
  display <- contrasts |>
    dplyr::filter(contrast %in% names(labels), inference == "primary") |>
    dplyr::mutate(contrast_label = factor(contrast, rev(names(labels)), rev(unname(labels))))
  ggplot2::ggplot(display, ggplot2::aes(estimate, contrast_label)) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60") +
    ggplot2::geom_pointrange(ggplot2::aes(xmin = conf_low, xmax = conf_high)) +
    ggplot2::facet_wrap(~position_label, ncol = 1) +
    ggplot2::labs(
      x = outcome_label, y = NULL, title = title,
      caption = caption
    ) +
    theme_paper()
}
