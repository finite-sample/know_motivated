# Motivated Responding in Studies of Factual Learning

Kabir Khanna and Gaurav Sood. 2018. *Political Behavior* 40(1): 79–101.
[Paper](https://doi.org/10.1007/s11109-017-9395-7) ·
[Dataverse V1](https://doi.org/10.7910/DVN/4JXJWI) ·
[Reproduced results](docs/results.md) · [Audit](docs/audit.md)

Three survey experiments examine whether small accuracy incentives change how
people report conclusions from hypothetical studies on concealed carry and the
minimum wage, and how credible they find those studies.

This archive preserves the released materials and rebuilds the analysis in R.
Historical-coding outputs reproduce the main concealed-carry and minimum-wage
percentages. Original Study 2
responses resolve a defect in its Dataverse wage fields: reconstructed accuracy
is 87.12%, matching the published 87%, rather than the release's 55.33%.
Full anonymized survey exports and historical coding files are included. The
pipeline reconstructs the analysis from the original answers, preserving the
Dataverse release unchanged. Primary results also correct numeracy scoring, interview-year ages, and
party-leaning recodes; separately labeled replication outputs retain historical
coding for exact comparisons. See [source recovery](docs/source_recovery.md)
and the [generated comparison](docs/results.md).

Verified repairs address Figure 5's recycled standard-error selector, Figure SI7's
wrong treatment denominators, and Figure SI4's ideological congeniality coding.
The audit also reports direct interaction tests, model-specific sample sizes,
missingness, and limits on the interpretation of the findings.

## Reproduce

Use R 4.6 and run from this directory:

```sh
make restore
make check
```

`make check` lints the maintained R code, rebuilds all outputs, runs the tests,
and compiles the [table preview](tabs/preview.pdf) and the
[corrected existing manuscript](paper/main.pdf). Table rendering requires
XeLaTeX and latexmk. `make archive` builds `data/build/know_motivated.tar.gz`.
`make analysis` rebuilds results without the development checks. `make download`
retrieves missing source files using the pinned manifest and verifies their hashes;
existing files must already match. Analysis itself works offline after restoration.

`make ci-docker` runs the same checks in `rocker/verse:4.6.0`, with a persistent
package cache. Docker must be running. `make format` applies styler formatting.

The lockfile pins the tested packages. Estimation uses `estimatr::lm_robust()`,
`emmeans`, and `broom`; Welch tests and historical logistic regressions use R's
`stats`, and scale reliability uses the original `psy` package. Main figures use worker-cluster CR2 for samples containing Study 1 records
and HC2 otherwise, with two-sided 95% t intervals. Each Study 2 row is assumed
to represent a different worker. Clustered contrasts use `estimatr::lh_robust()`
with contrast-specific degrees of freedom. A separately labeled HC0/normal
output reproduces the original binary-outcome uncertainty convention. Details and
package documentation are in [inference.md](docs/inference.md).

## Files and pipeline

| Path | Contents |
|---|---|
| `data/raw/dataverse/` | All 19 released files, the three original RData versions, and dataset metadata; unchanged bytes |
| `data/reference/paper/` | Author manuscript and published supplement used for the audit |
| `data/extracted/` | Full survey exports, historical coding files, and linkage to released records; direct identifiers removed or replaced with consistent pseudonyms |
| `data/reference/questionnaires/` | Original questionnaires |
| `docs/archive_inventory.csv`, `docs/survey_columns.csv` | Source-file inventory, question labels, and every retained, pseudonymized, or removed column |
| `docs/sources.csv` | Download URLs, version, retrieval time, hashes, and source terms |
| `docs/variable_names.csv` | Original-to-snake_case variable mapping |
| `R/` | Reusable preparation, estimation, figure, supplement, and audit functions |
| `scripts/00_config.R` | Paths and figure defaults |
| `scripts/01_prepare_data.R` | Verify sources; compare RData and tabular values; prepare respondent and task records |
| `scripts/02_estimate.R` | Estimate main and supplementary results |
| `scripts/03_figures.R` | Generate PDF and PNG figures |
| `scripts/04_audit.R` | Compare publication targets, reproduce bugs, and run sensitivity checks |
| `scripts/05_report.R` | Generate the numerical results summary from tables |
| `scripts/06_tables.R` | Generate LaTeX tables and a standalone exhibit preview |
| `scripts/07_paper_numbers.R` | Generate manuscript values and their source ledger |
| `paper/` | Existing author manuscript and newer SI, corrected and linked to generated results |
| `scripts/99_run_all.R` | Execute the stages in order |
| `scripts/extract_surveys.R` | Rebuild the full anonymized research exports from the private source ZIP; `make extract` |
| `data/build/` | Rebuildable data, original-script logs and session information; ignored by Git |
| `tabs/`, `figs/` | Generated public tables and figures |
| `tests/testthat/` | Source integrity, sample construction, inference, repair, and reproduction tests |

This follows the organization of [know_hidden](https://github.com/finite-sample/know_hidden).
New names use snake_case; data stages use `raw`, `extracted`, `reference`, and `build`. Original
source names remain intact. The supplied final manuscript and supplement sources are preserved under
`data/reference/manuscript/`; those originals are unchanged. `paper/` contains
the existing manuscript with verified numerical, inferential, and exhibit
corrections. Its repeated results and supplementary tables are generated from
the analysis. [Manuscript changes](docs/manuscript_changes.md) records the scope.
See [coverage.md](docs/coverage.md) for every published exhibit and its producing output.

A passing build verifies this implementation and its documented discrepancies;
it does not certify agreement with every published result. Study 2 wage responses
and questionnaire scoring are independently checked; recruitment, delivery, and
the final Dataverse export code remain incompletely documented.
