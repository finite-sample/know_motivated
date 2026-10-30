# Audit of the replication materials

The principal concealed-carry and minimum-wage percentages reproduce after
reconstructing four Study 2 wage fields from original responses supplied by the
user. The recovered accuracy is 825/947 (87.12%), consistent with the published
87%. Dataverse V1 contains 524/947 (55.33%); that is a release-file defect, not
evidence that the published accuracy rate is wrong.

The audit used Dataverse V1, both tabular and original RData formats, the author
manuscript, the published supplement, and the newly supplied source ZIP.
[sources.csv](sources.csv) and [recovery_sources.csv](recovery_sources.csv) pin
source bytes. [source_recovery.md](source_recovery.md) documents the raw responses,
questionnaire key, exact linkage, and correction. Original files remain unchanged.
[results.md](results.md) is generated from the maintained analysis.

## Findings and repairs

### Study 2 wage discrepancy resolved from original responses

All 947 original analysis records match the earlier survey export by response ID.
Their four branch responses and four introduction markers agree exactly. An
independent, unique match on 20 unaffected variables links those records to the
released respondents. No wage assignment or outcome enters the linkage.

The source questionnaire independently identifies the correct answer and
incentive for each branch. Reconstructing from those responses gives SI7 means
90.2%, 83.9%, 89.7%, and 87.4%, matching all published cells. All eight pooled
Figure 4 cells also reproduce, as do the eight Study 3 cells. The
[comparison figure](../figs/wage_replication_comparison.png) retains the published,
Dataverse, and reconstructed values. The earlier 55.3% finding correctly described
the released file, but it must not be presented as the corrected study result.

The release changes 354 wage-incentive assignments, 354 wage-version assignments,
313 observed congeniality fields, and 301 correct responses to incorrect. The
released assignment fields exactly follow the gun-task assignments except for
wage branch 8; released correctness loses correct responses when that erroneous
assignment disagrees with the actual wage branch. The final export script is
absent, so the precise historical statement responsible remains unknown.

Recovered gun/wage incentive counts (rows gun 0/1, columns wage 0/1) are
239/245 and 238/225, compared with 355/129 and 0/463 in the release. All 16 joint
assignment combinations are now observed. The recovered Study 2 supplementary
factorial logit has full rank 16/16, with 613 complete cases; this resolves the
rank deficiency caused by the released fields. The published label of 818 still
does not equal the 613 complete cases; model N is calculated from the actual
estimation sample.

**Repair:** the default pipeline reconstructs all analysis fields from full
anonymized survey exports. Historical-coding outputs isolate the four-field
wage repair; primary outputs additionally fix numeracy and party coding. Both native and tabular Dataverse files
remain immutable. Source reconstruction, row conservation, unchanged fields,
package-based inference, and agreement with published cells are tested. The
private source ZIP is not required for ordinary analysis; `make extract` can
regenerate the extract when that ZIP is available.

### Figure 5 standard-error selectors

In `fig5.R`, the mean calculation selects one incentive value with `[i]`, but the
standard-deviation calculation compares the respondent vector against the whole
four-element sequence. R recycles this sequence across rows, creating an
order-dependent subset. For incentivized carry supporters the contrast SE changes
from 0.236267 to 0.228625; the effect remains 0.406548. The corresponding original
90% interval changes from [0.017923, 0.795172] to [0.030493, 0.782603].

**Repair:** a saturated `estimatr` model and `emmeans` contrast compute the
uncertainty from the actual treatment cells. The generated repair table isolates
this fix. A shuffle test ensures that the corrected result is invariant to row
order. The modern figure additionally uses two-sided 95% t intervals; that is a
transparent inference choice, separate from the coding error.

### Figure SI7 uses the other task's treatment denominators

The original means use wage incentives (`acc2`), but the sample sizes use gun
incentives (`acc`). With the recovered data, original-script counts are
184/184/174/167, whereas the actual wage cells contain 174/192/184/159 respondents.
The original script's SEs round to the published 2.2/2.7/2.3/2.6, establishing
that this narrower denominator error affects the published figure's uncertainty.
The four means are unchanged by this repair and reproduce the publication.

**Repair:** derive outcomes and counts from the same task records and fit the
model on that sample. `wage_denominator_repair.csv` isolates original versus
correct denominators and package-based HC0 standard errors using the recovered
responses for both calculations. The modern figure additionally uses HC2/t
intervals, a separately documented inference convention.

### Figure SI4 did not recode congeniality to match its stated construct

The original script selects conservative Republicans and liberal Democrats but
continues to use congeniality relative to the respondent's gun policy preference.
The manuscript describes congeniality relative to ideological worldview.

**Repair:** define worldview congeniality from the assigned pro-/anti-gun result
and ideological group. Report both the coding change on the original policy-known
sample and the worldview-defined sample that also includes people with no stated
gun preference. These answer different sample questions. Within the primary corrected-coding sample, conservative Republican interactions
are 6.88 pp using policy congeniality, 20.28 pp using worldview congeniality
on the same sample, and 19.47 pp in the full worldview sample. Liberal Democrat
estimates are -8.33, -10.18, and -11.80 pp. `worldview_coding_comparison.csv`
records the estimates and uncertainty. The regenerated SI4 uses 199 conservative
Republicans and 701 liberal Democrats. These numbers also incorporate the
separate raw-response party correction described below.

### Credibility-bias claims require a direct interaction test

The abstract and discussion describe incentives as increasing the congeniality
bias in ratings. Separate significant and nonsignificant tests in the incentive
and control arms do not test that increase. The direct pooled interaction is
about 0.34 rating points, with an interval spanning both zero and a meaningful
increase. Subgroup interactions are likewise imprecise; the generated results
report them directly. The literal decline-in-ratings interpretation is also
incorrect: among uncongenial conditions the pooled mean rises from about 4.57
to 5.01 with incentives. A relative congeniality gap and an absolute mean change
are different quantities.

**Action:** describe a positive but uncertain interaction. Correct-only rating
analyses remain explicitly descriptive because correctness is post-treatment.
The archive does not identify whether any rating change is a sincere credibility
judgment, expressive responding, or another response-process change.

### Inference and transcription

- With historical coding, the pooled carry-opponent interaction is -18.34 pp:
  HC0/normal p=.0499 and HC2/t p=.0515. Correct numeric scoring adds one eligible
  Study 2 record, giving -17.85 pp and HC2/t p=.0575. Worker-cluster CR2 gives
  p=.0554; excluding the two unanswered Study 1 items gives -18.29 pp and p=.0499. The effect and uncertainty are more informative than a binary
  significance label. The published logit interaction is also near this boundary.
- The Study 3 carry-opponent incentive effect is +6.93 pp. The paper's p<.06
  is a one-sided calculation; the original two-sided value is about .118.
  Modern outputs explicitly identify their two-sided convention.
- The manuscript calls the published minimum-wage attenuation significant, but
  its displayed -11.0 pp estimate and 7.4 pp SE do not establish a .05 result
  under either a one- or two-sided normal test. This issue is separate from the
  released-data discrepancy.
- Published SI3 Study 3 sample sizes are 918 and 262, but the actual models use
  683 wage supporters and 369 opponents. The opponent congeniality z statistic
  is 3.7076, not the printed .679. Generated model tables obtain N and statistics
  directly from fitted objects.
- Original race balance tests for Studies 1/2 use incentives alone, while other
  covariates use the policy-congeniality factorial. Both specifications are
  retained with clear labels, alongside assigned-version factorial tests. Their
  differing samples and hypotheses are exposed. Average balance p-values do
  not establish correct randomization.

### Interview-year ages and unanswered response directions

The historical age calculation uses 2014 for both MTurk studies. Original start
timestamps place 281 retained Study 1 records in 2013 and all Study 2 records in
2015. Primary age now uses interview year minus birth year. This changes 281
Study 1 ages and 946 observed Study 2 ages, moving 13 and 62 records between age
categories. The exact birthday is unavailable, so age remains approximate.

Two unanswered Study 1 gun items were historically scored zero. Inferring a
reported answer from those zeros invented response directions. SI9/SI10 now
exclude these items: one cell changes from 124/216 to 123/215 congenial answers,
and another from 71/128 to 71/127. Historical correctness scoring and the
observed-answer sensitivity analysis remain distinct.

Primary inference now uses worker-cluster CR2 for samples containing Study 1.
Each Study 2 record is assumed to be a different worker. `estimatr::lh_robust`
supplies contrast-specific degrees of freedom; the independent-row HC2 estimates
remain separately labeled. This accounts for correlated records but does not
remove possible effects of repeat exposure to the task.

Two exclusion sensitivities are provided in `source_coding_sensitivity.csv`.
Retaining each worker's earliest eligible Study 1 response leaves 749 records;
excluding all records from repeated Study 1 IDs leaves 715. Study 2 is unchanged.
For the pooled concealed-carry opponent interaction, the estimates are −17.1
percentage points (p=.072) and −20.3 points (p=.034), respectively, compared
with −17.9 points (p=.055) in the full sample. The exclusion rule should be
chosen from the participation design, not from which p-value crosses .05.

### Documentation and measurement

Numeracy is a 0–5 item count, exactly equal to the sum of the five released items;
it is not the 0–1 score described in the codebook. The maintained data provide
both `numeracy_count` and `numeracy_share`. Study 3 importance items run 1–5,
whereas Studies 1/2 run 0–4; their `_raw` names preserve this distinction. The original raw answers expose 13 valid fifth-item responses written as `0.10`
(4 in Study 1, 9 in Study 2) that a string-only historical scorer rejected.
Numeric scoring fixes all 13. This resolves the apparent Study 1 screening
exception: the supposedly low-numeracy respondent has four correct answers.
One Study 2 respondent additionally enters the high-numeracy analysis pool.
Other-party leaners were coded in the opposite direction to independent leaners;
correcting this changes 15, 10, and 5 party codes in Studies 1, 2, and 3.
`raw_coding_changes.csv` and `source_coding_sensitivity.csv` retain the comparisons.

The 785 Study 1 records represent 749 distinct worker IDs, with 34 workers
contributing 70 records. Primary worker-cluster CR2 inference is provided; each Study 2 record is
assumed to represent a different worker because its worker IDs are missing. Two Study 1
respondents entered the gun task without answering it. Their historical zero
scores are retained in primary results, with observed-answer sensitivity shown.

Original main Figure 2/3/5 captions reverse the group labels relative to the
plots. The modern plots explicitly label groups. SI Table 11 describes joint
confidence/correctness proportions without saying they are restricted to no
incentives; generated tables identify the incentive condition. Supplementary
stimulus pro-/anti-gun labels are reversed relative to the displayed ratios.
The supplied questionnaire and raw branches resolve Study 2 wage scoring. The
supplementary gun-stimulus label discrepancy remains distinct from that repair;
this audit does not establish every fielded questionnaire version or delivery log.

## Claims and estimands

| Claim | Quantity and purpose | Design and implementation | Interpretation supported by the archive |
|---|---|---|---|
| Incentives reduce motivated responding | Incentive-by-congeniality interaction in correctness, by pretreatment policy attitude | Respondent-level factorial experiment; gun and recovered wage means reproduce | Changes in reports in these samples; latent learning versus recomputation or response criteria is not separately observed |
| Carry supporters learn in a motivated manner | Congeniality gap that persists under incentives | Randomized result direction; incentive response may be incomplete | Persistent correctness gap, not proof that all remaining bias is learning |
| Incentives increase credibility bias | Difference between congeniality effects in average 0–10 ratings | Post-task ratings; direct interaction now estimated with robust inference | Positive, imprecise interaction; correctness-conditioned analyses are descriptive |
| No selective perception | Congeniality differences in recalled table counts | Study 1 recall regressions; original targets are 223, 75, 107, 21 | Small estimated signed differences; wide intervals and absence of equivalence testing limit the claim |
| Few become confidently incorrect | Joint share certain and incorrect among Study 3 control respondents | Observed confidence and correctness; explicit joint denominator | Descriptive joint prevalence; not the error rate conditional on certainty |
| No spillover between tasks | Gun-treatment coefficients in wage correctness models | Fixed task order; recovered Study 2 model has full factorial rank | Nonsignificant coefficients do not establish no spillover; task order is not randomized |

All estimates are for recruited MTurk or Qualtrics survey participants in
2013–2016, not a probability-weighted national population. The gun and wage
tasks differ in topic, numerical presentation, and order. Their difference in
accuracy does not identify a causal effect of making a task easier.

## Comparison-group levels and plausibility

In the principal gun pool, the no-incentive/uncongenial correct-answer rates are
42.6% for carry supporters and 41.0% for opponents. In Study 3 they are 33.6%
and 25.6%. These correspond to fewer than half of respondents selecting the
correct answer. A 50% benchmark describes uniform random guessing between two
options; it is not an empirical expectation for this deliberately misleading
ratio task. The displayed marginal counts can cue an incorrect answer. These
levels are feasible and reproduce; their difference across studies is material
and warns against assuming a common response process or population.

There is no matched external benchmark establishing the expected baseline for
these particular tasks. National attitude proportions in the original supplement
are different outcomes and are not used as accuracy benchmarks. The wage
baseline discrepancy was resolved by directly matching original responses and
reconstructing questionnaire scoring. The published wage levels reproduce; no
expected accuracy benchmark was used to select the correction.

## Coverage of checks

| Check | Evidence and outcome |
|---|---|
| Tier 1: denominators/units | Respondent-task keys; counts by actual task assignment; SI7 repaired; joint versus conditional confidence shares distinguished |
| Tier 1: missingness | Blank categorical fields become NA, matching RData; two historical unanswered Study 1 zeros explicitly identified; missingness by study/task/incentive exported |
| Tier 1: row conservation | 2,794 respondents and 4,803 task records; unique keys and one-to-one publication comparisons tested |
| Tier 1: provenance | Source hashes; variable map; typed publication targets; generated results report; supplied final manuscript and SI sources preserved unchanged |
| Tier 1: internal consistency | Published versus archived cell comparisons; panel labels and SI3 transcription recorded |
| Tier 2: EDA | Full mechanical data sweep run; per-study scales, structural missingness, age outlier and recall tails examined; no evidence-based recode for anomalous age 114 |
| Tier 2: joins/construction | Native/tab agreement and explicit cardinality; reconstructed numeracy and congeniality; rating requires both items |
| Tier 2: estimands/inference | Unweighted respondent means; original and modern inference labeled; direct interactions, HC3 and Holm checks; pooling sensitivity |
| Tier 2: skew/influence | Correctness bounded; recall can be highly skewed; gun leave-one-out range and leverage exported; recalled means are not recall accuracy |
| Tier 3: design | Assignment-cell support inspected; raw exports recover sample selection; delivery/payment and upstream enrollment remain incompletely verified |
| Tier 3: interactions/simulation | Direct rating interactions; synthetic factorial truth test and independent package checks; no external effect size chosen for retrospective Type S/M calculations |
| Tier 4: rank/support | SI3 release rank deficiency resolved by source reconstruction; gun condition number, leverage, influence, study-specific and study-adjusted specifications exported |
| Tier 4: measurement | Item count rederived; rating alpha reproduced; no claim that alpha establishes invariance or validity; raw scale differences preserved |
| Paper moves 1–3 | Numeracy components verified; rating components and floor/ceiling range visible; dose response inapplicable to a binary incentive |
| Paper moves 4–7 | Incentive receipt/delivery and latent processing cannot be independently verified; no identified compliance measure for ITT-to-TOT; no matched external accuracy benchmark |
| Paper moves 8–12 | Interaction uncertainty, multiplicity and influence checked; reports distinguished from learning/behavior; all main contrasts and nulls retained; population and task limits stated |
| Other econometric designs | IV, RD, longitudinal DiD, prediction and causal machine learning are inapplicable; the reported “DiD” is a randomized factorial interaction, not a panel estimator |

The mechanical sweep's missingness flags mostly reflect questions not asked in
all studies. A high pooled missing rate is not evidence of attrition. The sweep
found no duplicate released record key; source worker IDs nevertheless identify
repeated participation in Study 1. Native and tabular data match after converting
factor labels and empty missing strings; these checks rule out plausible import
artifacts. The user-supplied original responses then resolved the Study 2 release
defect; the test suite retains both the released and recovered results.

## Remaining evidence needed

Study 2 wage responses and questionnaire scoring have been recovered and checked.
The code that produced the final Dataverse export is still missing. Assignment
implementation, delivery and payment logs, upstream enrollment records,
and any preregistration require further reconciliation before making claims
about compliance, attrition, or prespecification. Published external benchmark
columns and eligibility counts remain documented context, not rebuilt microdata
results. No claim is made that these additional checks passed.

The existing manuscript is now maintained in `paper/`, with numerical results
and SI tables linked to the analysis. Definite credibility-bias, no-spillover,
and no-selective-perception conclusions have been qualified to match the tests.
Original author and publisher files remain unchanged under `data/reference/`.
