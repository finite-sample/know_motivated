# Exhibit coverage

Original scripts remain under `data/raw/dataverse/`. The modern pipeline produces
numerical content with consistent labels rather than reproducing historical page
layouts. All statistical output is package-derived. Figure confidence conventions
are described in [inference.md](inference.md).

| Publication artifact | Original source | Modern output |
|---|---|---|
| Main Figure 1 | Conceptual diagram in paper | Preserved manuscript/PDF; no estimated quantities |
| Main Tables 1–2 | Hypothetical stimulus tables | Preserved manuscript/PDF; literal numbers, not participant estimates |
| Main Figure 2 | `fig2.R` | `accuracy_cells.csv`, `accuracy_contrasts.csv`; `figure_2*` |
| Main Figure 3 | `fig3.R` | Same tables; `figure_3*` |
| Main Figure 4 | `fig4.R` | Same tables; `figure_4*`; Study 2 fields reconstructed from original responses |
| Main Figure 5 | `fig5.R` | `rating_cells.csv`, `rating_contrasts.csv`; `figure_5*` |
| SI Figures 1–3 | `fig.si1.R`–`fig.si3.R` | `participant_flow.csv`; `figure_si_1*`–`figure_si_3*`; source export and released sample counts |
| SI Figure 4 | `fig.si4.R` | Accuracy tables; `figure_si_4*`; corrected ideological coding and comparison CSV |
| SI Figures 5–6 | `fig.si5.R`, `fig.si6.R` | Accuracy tables; `figure_si_5*`, `figure_si_6*` |
| SI Figure 7 | `fig.si7.R` | Accuracy tables; `figure_si_7*`; denominator repair and source reconstruction documented |
| SI Figure 8 | `fig.si8.R` | Accuracy tables; `figure_si_8*` |
| SI Table 1 | `table_and_misc_numbers.R` | `sample_characteristics.csv`; national benchmark column remains source context |
| SI Table 2 | Same | `balance_tests.csv`, `model_coefficients.csv`, `race_balance_checks.csv` |
| SI Table 3 | Same | `model_coefficients.csv` (`wage_logit_*`); model N/rank and NA terms explicit |
| SI Table 4 | Same | `numeracy_cells.csv`, `numeracy_incentive_effects.csv` |
| SI Tables 5–6 | Same | `recall_cells.csv`, `model_coefficients.csv` (`recall_*`) |
| SI Tables 7–8 | Same | `model_coefficients.csv` (`gun_logit_position_*`) |
| SI Tables 9–10 | Same | `response_bias.csv`; shares of congenial answers and complementary uncongenial shares |
| SI Table 11 | Same | `confidence_joint.csv`; both incentive arms exported; publication uses arm 0 |
| Ratings text and footnotes | Same | `rating_welch_tests.csv`, `rating_reliability.csv` |
| Attitudes and overall correctness | Same | `overall_means.csv` |
| Numeracy-specific response odds | Same | `response_bias_pooled.csv` |

New diagnostic artifacts include publication comparisons, missingness by
assignment, task assignment cross-tabs, corrected standard-error comparisons,
worldview coding comparisons, gun specification/influence checks, and multiplicity
checks. The pipeline writes session information to `data/build/session_info.txt`.

Full source exports recover 1,278, 1,456, and 1,067 survey records and the
selection into released samples. Flow figures show these source counts and
overlapping analytical subsets explicitly. Upstream recruitment beyond these
exports is not reconstructed. `survey_flow.csv` records included and excluded
counts, and `participant_identity.csv` documents repeated worker IDs.

`table_si_1.tex`–`table_si_11.tex` contain regenerated numerical tables.
`preview.pdf` compiles these tables with main contrasts and coding sensitivity.
Final author TeX, bibliography files, and publisher PDFs are preserved unchanged
in `data/reference/manuscript/`. Original figure files referenced by the TeX
were not included, so these sources alone are not a standalone manuscript build.
Primary exhibits use corrected coding; exact published-cell comparisons use
`replication_accuracy_cells.csv`.

`paper/main.tex` and `paper/supplement.tex` revise the existing author sources.
They include the generated SI tables and figures. `paper_numbers.csv` records
each inline result's key, formatted value, and producing artifact. `make paper`
builds the combined manuscript and SI; it preserves the original conceptual
figure as a clipped view of the publisher PDF.
