if (!file.exists("DESCRIPTION") || read.dcf("DESCRIPTION")[1, "Package"] != "motivated") {
  stop("Run from the know_motivated project root.")
}
project_root <- normalizePath(".")
project_file <- function(...) file.path(project_root, ...)
raw_dir <- project_file("data", "raw", "dataverse")
build_dir <- project_file("data", "build")
table_dir <- project_file("tabs")
figure_dir <- project_file("figs")
figure_dpi <- 180
figure_width <- 9
figure_height <- 6
incentive_labels <- c("No incentive", "Incentive")
condition_labels <- c("Uncongenial", "Congenial")
condition_colours <- c("#626262", "#08519c")
theme_paper <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold"),
      legend.position = "bottom",
      plot.caption = ggplot2::element_text(hjust = 0)
    )
}
for (path in c(build_dir, table_dir, figure_dir)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
for (path in sort(list.files("R", pattern = "[.]R$", full.names = TRUE))) source(path)
exhibit_titles <- c(
  figure_2 = "Concealed carry: Studies 1 and 2",
  figure_3 = "Concealed carry: Study 3 (uncongenial results)",
  figure_4 = "Minimum wage: Studies 2 and 3",
  figure_si_4 = "Concealed carry: ideological worldview",
  figure_si_5 = "Concealed carry: Study 1",
  figure_si_6 = "Concealed carry: high-numeracy Study 2",
  figure_si_7 = "Minimum wage: Study 2 supporters",
  figure_si_8 = "Minimum wage: Study 3"
)
flow_labels <- c(
  n_archived = "Released records", n_outcome = "Observed gun-task response",
  n_position = "Stated gun-policy position", n_supporters = "Concealed-carry supporters",
  n_opponents = "Concealed-carry opponents"
)
