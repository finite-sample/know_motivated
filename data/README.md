# Data provenance and definitions

The replication archive is Harvard Dataverse DOI
[10.7910/DVN/4JXJWI](https://doi.org/10.7910/DVN/4JXJWI), version 1.0,
released February 26, 2017 under CC0. Its 19 source files are preserved in
`raw/dataverse/`, together with the three original RData representations and the
API metadata response. Both data formats are retained so their equality can be
verified. Dataverse's metadata MD5 for an ingested table refers to the original
RData file, not the generated tab-separated representation. SHA-256 pins both.

`../docs/sources.csv` records individual download URLs, version, retrieval time,
local hashes, published checksums where applicable, and source terms. Downloads
use the documented [Dataverse Data Access API](https://guides.dataverse.org/en/latest/api/dataaccess.html).
Source files are never edited. `make download` only fills missing files and
rejects bytes that differ from the manifest. Analysis performs no downloads.

The author manuscript and journal supplement in `reference/paper/` support the
audit. They have separate source terms; Dataverse's CC0 does not apply to them.

## Row units and samples

The released studies contain 785, 947, and 1,062 records. Study 1 has 749
distinct worker IDs: 34 workers account for 70 records. Study 2 worker IDs are
missing; each Study 2 row is assumed to represent a different worker. Original `respid` values are
unique only within study. `respondent_key` combines study and respondent ID.
`build/respondents.rds` contains one row per released record;
`build/tasks.rds` contains one row per respondent-task (gun in all three studies,
wage only in Studies 2 and 3). The latter has 4,803 rows before analysis restrictions.

The principal gun pool keeps all released Study 1 respondents and those scoring
at least four in Study 2. Analyses then require the relevant policy position,
assignment, and outcome. Study 3's gun task has only uncongenial stimuli.
Missing policy positions do not mean neutral or incorrect. Study 1 has two assigned but unanswered gun items historically scored zero;
this convention is retained and an observed-answer sensitivity analysis is
provided. Other missing outcomes remain missing. Ratings require both items.
Questions not asked in a study remain structurally missing after pooling.

## Names and coding

[variable_names.csv](../docs/variable_names.csv) maps every released variable to
its maintained snake_case name. Publisher names remain unchanged in source files.
The original codebook describes item wording, subject to these verified corrections:

- `numeracy_count` is the sum of five binary items, 0–5. `numeracy_share` divides
  it by five. `is_high_numeracy` means at least four correct items.
- `gun_ban = 1` favors a ban, so describes a concealed-carry **opponent**.
  `wage_support = 1` supports increasing the minimum wage.
- `gun_anti = 1` assigns the anti-gun result. For Studies 1/2,
  `gun_congenial` equals `gun_anti == gun_ban` when the policy stance is known.
- `wage_pro = 1` assigns the pro-wage result. For Study 2,
  `wage_congenial` equals `wage_pro == wage_support`; the assigned-version field
  itself is not released for Study 3.
- Worldview congeniality uses the result direction relative to liberal Democrat
  versus conservative Republican membership. It does not reuse policy congeniality.
- `gun_importance_raw` and `wage_importance_raw` run 0–4 in Studies 1/2 and 1–5
  in Study 3. They are not pooled as a common scale.
- Education order follows the original R factor levels: high school or less,
  some college, college degree, postgraduate. Empty categorical strings are NA.
- `is_white` is missing when race/ethnicity is missing, not zero.

## Full source inputs and reconstruction

`extracted/surveys/study_1.csv`, `study_2.csv`, and `study_3.csv` retain all
1,278, 1,456, and 1,067 survey records, including excluded records. The three
`extracted/coding/` files preserve historical recodes and their raw responses.
`docs/archive_inventory.csv` inventories all 65 source ZIP members and identifies
superseded versions and administrative files. `docs/survey_columns.csv` records
original headers, question labels, and each retention or de-identification action.
Direct identifiers are removed or replaced by consistent pseudonyms; research
responses and timing fields are preserved. The private original ZIP remains
locally in `raw/private/source_bundle.zip` and is excluded from the public archive.

`R/surveys.R` constructs outcomes, assignments, covariates, and sample membership
from these full exports. Study 1 selects US records with a worker ID and an
observed task introduction; Study 2 selects records with one answer to each task;
Study 3 selects US records. These rules reproduce the released samples exactly.
The source-to-release linkage uses all reproducible released fields (excluding
Study 2's four corrupted wage fields). Three Study 3 records have identical
released profiles; their within-profile linkage is deterministic but cannot
identify which physical record received which arbitrary released ID.

Primary data correct 13 numeracy responses written as `0.10` that the historical
string comparison rejected, and 30 reversed other-party leaner codes. Historical
coding remains available in `build/replication_respondents.rds` and
`tabs/replication_accuracy_*.csv`. `tabs/raw_coding_changes.csv` and
`tabs/source_coding_sensitivity.csv` expose the changes and their consequences.
The fifth numeracy answer is scored numerically as 0.1; other-party leaners use
the same Republican/Democratic direction as independent leaners. Study 1's
third and fourth numeracy items have the opposite order to Studies 2/3.

All correctness outcomes are reconstructed from branch-specific raw answers.
[Source recovery](../docs/source_recovery.md) documents the Study 2 wage repair.
`R/source_archive.R` and `make extract` rebuild the public research exports from
the private original ZIP. Ordinary replication needs only the shipped files.
The historical final-export/cleaning scripts were not supplied; the new R code
makes every transformation explicit and tests it against the released records.

Derived data are regenerated under `build/`. Source hashes, full-field equality,
sample counts, coding fixtures, and publication comparisons guard the pipeline.

Interview year is derived from the original start timestamp before exact dates
are removed. Primary age is interview year minus birth year (approximate because
birth month/day are unavailable). Historical comparisons retain the original
2014 reference year for Studies 1/2. This changes 281 Study 1 ages and 946
observed Study 2 ages; 13 and 62 age categories change.

Primary uncertainty accounts for known repeated Study 1 workers using CR2.
Study 2 records are treated as distinct workers. Response-direction tables
exclude unanswered items even where historical correctness scoring uses zero.

`worker_attempt` in the Study 1 survey export orders eligible task entries within
worker by the original start timestamp, breaking exact timestamp ties by source
row. The first-participation sensitivity retains the first eligible entry per
worker. The original timestamps are not published. Other exports use a value of
1 without identifying repeated participation; analysis assumes Study 2/3 records
are distinct participants.
