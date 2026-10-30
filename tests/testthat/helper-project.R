project_root <- normalizePath(file.path("..", ".."))
withr::with_dir(project_root, source("scripts/00_config.R", local = FALSE))
respondents <- readRDS(file.path(build_dir, "respondents.rds"))
tasks <- readRDS(file.path(build_dir, "tasks.rds"))
