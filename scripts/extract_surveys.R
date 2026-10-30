source("scripts/00_config.R")
arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1) stop("Supply the path to the original source ZIP.")
extract_surveys(arguments[1])
