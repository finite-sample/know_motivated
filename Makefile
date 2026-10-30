.DEFAULT_GOAL := analysis
.PHONY: restore download extract analysis tables paper format lint test check ci-docker archive

SOURCE_ARCHIVE ?= data/raw/private/source_bundle.zip

extract:
	Rscript scripts/extract_surveys.R "$(SOURCE_ARCHIVE)"

restore:
	Rscript --no-init-file -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", repos = "https://cloud.r-project.org"); renv::load(project = getwd()); renv::restore(prompt = FALSE)'

download:
	Rscript scripts/download_sources.R

analysis:
	Rscript scripts/99_run_all.R

tables: analysis
	cd tabs && latexmk -Werror -xelatex -interaction=nonstopmode -halt-on-error preview.tex

format:
	Rscript -e 'styler::cache_deactivate(); for (path in c("R", "scripts", "tests")) styler::style_dir(path)'

lint:
	Rscript -e 'issues <- unlist(lapply(c("R", "scripts", "tests"), lintr::lint_dir), recursive = FALSE); print(issues); quit(status = as.integer(length(issues) > 0))'

test: analysis
	Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'

paper: analysis
	cd paper && latexmk -Werror -xelatex -interaction=nonstopmode -halt-on-error main.tex

check: lint test tables paper

ci-docker:
	docker run --rm -v "$(CURDIR):/project" -w /project \
		-v motivated_renv_cache:/root/.cache/R/renv \
		-e RENV_CONFIG_REPOS_OVERRIDE=https://packagemanager.posit.co/cran/latest \
		rocker/verse:4.6.0 bash -c "make restore check"

archive: check
	COPYFILE_DISABLE=1 tar -czf data/build/know_motivated.tar.gz \
		--exclude='*.aux' --exclude='*.log' --exclude='*.out' --exclude='*.fdb_latexmk' --exclude='*.fls' --exclude='*.xdv' --exclude='*.bbl' --exclude='*.blg' \
		README.md DESCRIPTION CITATION.cff Makefile .Rprofile .gitignore .gitattributes .lintr renv.lock renv/activate.R renv/settings.json \
		.github R scripts tests docs data/README.md data/raw/dataverse data/extracted data/reference data/build/session_info.txt tabs figs paper
