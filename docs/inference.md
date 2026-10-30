# Estimation and inference

The primary unit is a survey record within a study. Primary analyses containing
Study 1 records cluster on its anonymized worker IDs. Each Study 2 row is assumed
to represent a distinct worker, both within Study 2 and relative to Study 1.
Study 3 records are treated as distinct participants.
Task records are unique on
`respondent_key` and `task`; the gun and wage tasks are never treated as independent
respondents in one pooled outcome regression. Analyses are unweighted sample
comparisons. Policy positions precede treatment. Study 1 and high-numeracy Study 2
respondents form the principal concealed-carry pool; Study 3 is separate because
it has only uncongenial gun stimuli.

## Package choices

- [`estimatr::lm_robust()`](https://declaredesign.org/r/estimatr/reference/lm_robust)
  fits saturated treatment models with explicit CR2 or HC2 covariance. The installed,
  tested version is recorded in `renv.lock`. CR2 accounts for known repeated Study 1 workers. The HC3 sensitivity analysis is separately labeled.
- [`emmeans`](https://rvlenth.github.io/emmeans/articles/interactions.html)
  supplies treatment-cell predictions, linear contrasts, interactions, confidence
  intervals, and tests. Contrast weights define the scientific question; the
  package computes the covariance propagation and inference.
- [`broom`](https://broom.tidymodels.org/) extracts model output without manually
  reconstructing coefficient tests. Base R `stats::glm()` reproduces historical
  logistic models and `stats::t.test()` reproduces Welch tests.
- [`marginaleffects`](https://marginaleffects.com/bonus/hypothesis.html) was also
  reviewed. It is well suited to response-scale comparisons and nonlinear
  hypotheses. These saturated linear factorial models need only emmeans, so the
  archive avoids a second overlapping marginal-inference interface.
- `psy::cronbach()` reproduces the original two-item reliability calculation.
  Alpha does not establish construct validity or unidimensionality.

There are no custom implementations of standard errors, degrees of freedom,
p-values, or confidence intervals in the maintained pipeline. Unmodified original
scripts are executed only to document historical behavior and verified defects.

## Contrasts and conventions

`congeniality_no_incentive` and `congeniality_incentive` are congenial minus
uncongenial means in the respective incentive arms. `interaction` is the second
contrast minus the first. The two incentive contrasts are incentive minus control
within each congeniality condition. Study 3's gun task identifies only the
incentive effect under an uncongenial result.

Primary samples containing Study 1 use CR2 with worker clusters. Intercept-only
cell models use `lm_robust`; each contrast is computed separately with
[`lh_robust`](https://declaredesign.org/r/estimatr/reference/lh_robust.html), which
returns its own Satterthwaite degrees of freedom, confidence interval, and test.
Ordinary emmeans output for a clustered `lm_robust` fit uses residual degrees of
freedom, so it is not used for primary CR2 contrasts. Other samples use HC2 and
residual t degrees of freedom; their cell models use cell-specific degrees of
freedom. `primary`, `hc2`, and `hc0_normal` are separately identified in contrast
exports. Clustering handles dependence, not possible learning from repeat exposure. `accuracy_contrasts.csv` also includes
`hc0_normal`: saturated HC0 covariance and normal reference inference, equivalent
to the original independent binomial-cell calculations. This is a reproduction
convention, not a claim that estimated variances are known.

The original Figure 5 used 90% normal intervals. The modern figure uses 95% worker-cluster CR2 t
intervals. `rating_standard_error_repair.csv` separately uses 90% normal intervals
and HC2 covariance to isolate the selector repair. Historic one-sided Welch tests
are clearly named in `rating_welch_tests.csv`; all modern contrast p-values are
two-sided. Confidence interval bounds from linear models are not truncated at
zero or one.

Default contrasts are unadjusted and exploratory. `multiplicity_check.csv`
reports Holm adjustment across the six main task-by-policy subgroup incentive
comparisons (four factorial interactions and two Study 3 gun effects). Study 2
wage fields use the documented original-response reconstruction. This retrospective family does
not recreate an unavailable prespecified plan.

Study-adjusted and separately estimated study results are sensitivity analyses;
all-numeracy results change the target sample. Confidence-by-correctness tables
use joint shares with the observed denominator, never the marginal minimum.
Rating analyses conditional on correctness are descriptive because correctness
is post-treatment.

No randomization inference is asserted: the exact assignment protocol is not
fully reconstructed. Recovered Study 2 data have support in all 16 joint
assignment cells, resolving the empty cells in Dataverse V1. No national population weights are supplied. Logit coefficients
are log-odds, while linear probability contrasts are probability differences.
Rank-deficient model outputs retain NA coefficients and expose rank and column
counts rather than pretending every coefficient is identified.

## Source coding

Primary figures and tables use reconstructed raw responses with corrected numeric
scoring, other-party leaning, and interview-year ages. `replication_accuracy_cells.csv` and
`replication_accuracy_contrasts.csv` retain historical numeracy and party coding
while repairing the corrupted Study 2 wage fields. Publication comparisons use
that historical-coding branch. The coding sensitivity table separates these
changes from CR2 inference and exclusion of two unanswered Study 1 gun items.

The first-participation sensitivity retains the earliest eligible Study 1 record
per worker, ordered using original survey start times. Study 2 records are all
retained under the distinct-worker assumption. This changes the analysis sample
and is reported separately from clustering the complete published sample.

The exclude-repeated-workers sensitivity removes all records from any Study 1
worker appearing more than once in the released sample. It retains 715 Study 1
records, compared with 749 when retaining first participation and 785 in the
full sample. Neither exclusion rule uses outcomes or treatment assignments.
