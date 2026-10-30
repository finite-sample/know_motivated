# Study 2 source recovery

The original survey responses reproduce the publication: 825 of 947 Study 2
respondents answered the wage question correctly (87.12%). They also reproduce
all four SI7 percentages and all eight pooled Figure 4 percentages within the
printed rounding. The 55.33% result belongs to the Dataverse V1 release, whose
wage fields differ from the original responses. It is not a correction to the
published accuracy rate.

## Sources and linkage

The user supplied `data-20261030T013420Z-1-001.zip`, retained locally as
`data/raw/private/source_bundle.zip`. [recovery_sources.csv](recovery_sources.csv) pins the ZIP and three
members by SHA-256:

- `data/plrRecode.csv`: the original 947-person analysis roster, including raw
  question responses and historical recodes.
- `data/mturk/Partisan_Learning_Replication.csv`: the earlier survey export.
- `data/qualtrics/questionnaire/Partisan_Learning_Qualtrics.docx`: the questionnaire
  with named branches, stimulus tables, response labels, and incentive wording.

All 947 roster records match the survey export by its response identifier, and
all eight `intro5`–`intro8` and `cvd5`–`cvd8` fields agree. Each respondent has
exactly one observed wage response. The original roster is linked to the public
release with an exact, unique, one-to-one match on 20 unaffected variables:
five numeracy items, sex, age, party identification, ideology, gun congeniality,
gun incentive, gun correctness, both gun ratings, gun ownership, both policy
positions, education, and both importance items. No wage treatment or outcome
enters this match. Row order and the source's old row numbers are not identifiers.

The linkage derives age as `2014 - yob`, maps education to the released factor
labels, and reverses the original 1–5 importance scores to the released 0–4
scale. It does not reuse the source's malformed legacy `age` column. These are
linkage conversions, not changes to the released demographic values. The code
stops on missing, duplicated, or unmatched keys rather than guessing a match.

## Questionnaire scoring

| Branch | Result direction | Incentive | Correct response |
|---|---|---|---|
| `cvd5` | Pro-wage | No | 2: increase in jobs |
| `cvd6` | Anti-wage | No | 1: decrease in jobs |
| `cvd7` | Pro-wage | Yes | 2: increase in jobs |
| `cvd8` | Anti-wage | Yes | 1: decrease in jobs |

In branches 5 and 7, job growth occurs in 37% of states that increased wages
versus 16% of states that did not. Branches 6 and 8 reverse those row labels.
Questions 7 and 8 explicitly offer a $0.10 accuracy bonus. The reconstructed
assignment and correctness fields agree with all corresponding historical
recodes in the original roster. No coefficients or published targets determine
the scoring.

The archive now includes all research responses in the full anonymized exports
under `data/extracted/`, together with historical recodes and the questionnaires.
`R/wage.R` derives the branch and response from these full inputs; no separate
minimal extract is needed. See [data definitions](../data/README.md) and the
[column inventory](survey_columns.csv) for identifiers removed or pseudonymized.
The original private ZIP is not required for ordinary replication.

## Results and scope

| SI7 supporters, N=709 | Correct / N | Reconstructed | Published |
|---|---|---:|---:|
| No incentive, uncongenial | 157 / 174 | 90.23% | 90.2% |
| No incentive, congenial | 161 / 192 | 83.85% | 83.9% |
| Incentive, uncongenial | 165 / 184 | 89.67% | 89.7% |
| Incentive, congenial | 139 / 159 | 87.42% | 87.4% |

Compared with Dataverse V1, 354 wage-incentive fields, 354 wage-version fields,
313 observed congeniality fields, and 301 correctness fields change. All 301
correctness changes restore answers scored correct in the original source.
The wage repair modifies only `acc2`, `prowage`, `wagecong`, and `cvdwage`;
all other values remain identical in the historical-coding replication. Primary
results additionally apply the independently verified numeracy and party recodes. All 16 cross-task assignment
combinations occur in the recovered data. The original release remains intact
and can be analyzed with `read_studies(raw_dir, use_survey = FALSE)`.

This localizes the large mismatch to the released Study 2 wage fields. The
script that created the final release was not included, so its exact faulty
statement cannot be identified from these files. However, the following
identities reproduce all 947 released rows exactly:

- Released wage incentive equals the gun incentive, except branch 8 is set to 1.
- Released pro-wage assignment equals the anti-gun assignment, except branch 8
  is set to 0.
- Released wage congeniality compares that assignment with the wage position.
- Released correctness equals true correctness AND agreement between the true
  and released wage-result direction.

This is consistent with using the other task's assignment for the first three
wage branches while handling the fourth correctly. It does not reveal the
literal historical code that caused the error. Separate figure-code and
manuscript issues are documented in [audit.md](audit.md); they should not be
conflated with the now-resolved accuracy discrepancy.

The [comparison figure](../figs/wage_replication_comparison.png) shows all three
sources. `tabs/wage_source_comparison.csv` retains the published, released, and
reconstructed percentages; `tabs/study_2_source_recovery.csv` records field changes.

## Reproduce

Normal `make check` uses the shipped full anonymized exports and verifies their
checksums. To regenerate those exports from the original private ZIP:

```sh
make extract SOURCE_ARCHIVE=/path/to/data-20261030T013420Z-1-001.zip
make check
```

`R/source_archive.R` verifies source hashes and performs de-identification;
`R/surveys.R` reconstructs and links all three studies. The maintained pipeline
scores raw responses rather than treating historical recodes as outcomes.
