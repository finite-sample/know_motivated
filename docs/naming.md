# Naming and organization

New files, variables, and functions use snake_case. Data names are nouns; function
and execution script names are verbs. `R/` contains reusable topic modules;
numbered `scripts/` define execution order. `00_config.R` owns paths and display
defaults. This follows know_hidden's separation of reusable code, execution stages,
source data, aggregate tables, figures, and tests.

Data stages are `data/raw/`, `data/extracted/`, `data/reference/`, and `data/build/`. Acquisition history
belongs in `sources.csv`, not folder names. Original Dataverse names and bytes are
preserved, with the source-to-analysis variable map in `variable_names.csv`.
Published exhibit numbers identify an external reference, not a data version.

R and tool conventions retain `DESCRIPTION`, `Makefile`, `README.md`, `CITATION.cff`,
`.Rprofile`, the `R` directory, `.R` extensions, and testthat's `test-*.R` filenames.
Third-party packages in ignored `renv/library/` are outside the naming contract.
Generated CSV columns use snake_case; human-facing report tables use readable
labels. Original-script object names are accessed only in historical diagnostics.

Names distinguish units and interpretation: `_count`, `_share`, `_pct`, `_pp`,
`_raw`, and `is_` carry meaning. Gun-ban supporters oppose concealed carry;
minimum-wage supporters favor an increase. A joint confidence/correctness share
is not a conditional error rate. The variable dictionary spells out these terms.
