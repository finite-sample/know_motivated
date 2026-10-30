source("scripts/00_config.R")
stages <- c("01_prepare_data", "02_estimate", "03_figures", "04_audit", "05_report", "06_tables", "07_paper_numbers")
for (stage in stages) {
  message("Running ", stage)
  sys.source(file.path("scripts", paste0(stage, ".R")), envir = new.env(parent = globalenv()))
}
writeLines(capture.output(sessionInfo()), file.path(build_dir, "session_info.txt"))
