---
name: g2e-diagnose
description: Root-cause a failing test or a wrong gtfs2emis result with a disciplined reproduce → minimise → hypothesise → instrument → fix loop, instead of guessing-and-poking. Use when the user says "this test fails", "debug this", "emissions are NA/zero/too high", "the EF looks wrong", "the output changed", "it works with parallel = FALSE but not TRUE", "this feed/fleet breaks transport_model() or emission_model()", or reports an error from a gtfs2emis function. Tuned for data.table + sf + units + future code: EF lookups, fleet data, speed ranges, units (km vs m, g/km vs g), by-reference mutation, worker side effects. Use `--no-fix` to localize the root cause without editing source.
argument-hint: "[function, test file, or short description of the symptom] [--no-fix]"
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash", "Agent"]
effort: high
---

# /g2e-diagnose — Root-Cause a Wrong or Failing Result

Find *why* a gtfs2emis function errors, returns `NA`/zero/implausible emission
factors or emissions, drops segments, or fails a test — with a structured
debugging loop rather than scattershot edits.

The discipline: **never edit before you can reproduce, and never fix before you
can explain.** A guessed fix that makes the symptom disappear without a named
root cause usually moves the bug somewhere a user will hit it.

## When to use

- A test in `tests/testthat/` fails, or `R CMD check` reports an error in an
  example or vignette.
- `transport_model()`, an `ef_*()` function, `emission_model()` or a summary
  function (`emis_summary()`, `emis_to_dt()`, `emis_grid()`) errors, or
  returns `NA`/`Inf`/zero/implausible values you can't explain.
- A result differs between runs, machines, fleets, package versions, or between
  `parallel = TRUE` and `parallel = FALSE`.

**Diagnose is symptom-driven and single-target: ONE wrong result / ONE failing
test.** For review with no specific symptom, use the review lenses in
`.claude/rules/orchestrator-protocol.md` instead.

## Phases

### Phase 0 — Pin the symptom (expected vs. actual)

- **Expected:** the result you believe is correct, and *why* (the EF source
  table or equation — EMEP/EEA, CETESB, MOVES, EMFAC —, a prior version's
  output, a hand calculation on the fixture, the documented behaviour).
- **Actual:** the result or error observed now, copied verbatim.

If expected/actual can't be stated, the task is *understanding*, not diagnosis —
stop and clarify first.

### Phase 1 — Reproduce deterministically

1. Reproduce with `devtools::load_all()` on a bundled fixture
   (`system.file("extdata/<irl_dub|bra_cur|usa_det>_gtfs.zip", package = "gtfs2emis")`
   with the matching `*_fleet.txt`) or the user's data. Record `sessionInfo()`
   and package versions (gtfs2gps, data.table, sf, units, future, furrr).
2. **Run with `parallel = FALSE` first.** Errors inside workers are harder to
   read; sequential mode surfaces them. If the bug appears only with
   `parallel = TRUE`, that is itself the leading hypothesis (Phase 3), and
   remember that workers load the **installed** gtfs2emis, not the
   `load_all()` one.
3. Confirm it fails **every time**. Intermittent failures point to worker
   scheduling, a stale installed package, or test-order dependence (shared
   fixtures in `tests/testthat/setup.R`).

### Phase 2 — Minimise to an MWE

- **Data:** shrink the feed to one shape
  (`gtfstools::filter_by_shape_id(gtfs, "<id>")`, as `setup.R` does) and the
  fleet to one row (`fleet_composition = 1`).
- **Code:** reduce to the shortest path. An EF symptom is usually reproducible
  by calling the `ef_*()` function directly with a few speeds
  (`units::set_units(c(10, 30, 60), "km/h")`), skipping `transport_model()`
  and `emission_model()` altogether.
- Each removal that *keeps* the bug is information; each that *kills* it is a
  stronger signal — record which.

### Phase 3 — Hypothesise (enumerate, then rank)

List candidate causes *before* testing any. gtfs2emis usual suspects (most run
with **no error** — silent wrong results):

- **EF lookup** — a `veh_type`/`euro`/`tech`/`fuel`/`model_year`/pollutant
  combination absent from the database (`data/*.rda`) giving `NA` or the wrong
  row instead of an error (each value valid on its own, the combination not).
- **Speed ranges** — speeds outside the EMEP/MOVES validity range, speeds
  rounded before the lookup, zero or `NA` speeds from `transport_model()`
  (`min_speed`/`max_speed`/`new_speed`).
- **Units** — km vs m for `dist`, km/h vs m/s, g/km vs g; `units` objects
  compared with plain numerics; units dropped and not restored.
- **Fleet data** — `fleet_composition` not summing to 1; a column the chosen
  `ef_model` needs is missing or misnamed; factors instead of characters.
- **Scaling / corrections** — `ef_scaled_euro()`, `fuel_correction()`,
  `slope_class_europe_emep()` slope classes, or `reference_year`/`model_year`
  age logic.
- **Aggregation** — `emis_summary()`/`emis_to_dt()` grouping by the wrong
  column; `emis_grid()` CRS mismatch or segments split across cells
  double-counted.
- **By-reference mutation** — `:=` / `setDT()` on the caller's `tp_model`,
  fleet or `emi_list` without `copy()`; a second call then sees altered input.
- **Parallel side effects** — `<<-` in workers, packages missing from
  `furrr_options(packages =)`, an outdated installed gtfs2emis on the workers.
- **Environment** — a gtfs2gps / data.table / sf / units version changed a
  default or a column in the `transport_model()` output.

For a genuinely ambiguous bug, fan out the top competing hypotheses to parallel
`Agent` subagents (one per hypothesis), each told to *try to confirm its own
cause on the MWE* and report back (see
[`orchestrator-protocol.md`](../../rules/orchestrator-protocol.md)).

### Phase 3b — Reduce the hypotheses

Each hypothesis returns `{hypothesis, evidence for, evidence against,
confidence, one-line conclusion}`. Then:

- **One clear winner** → Phase 4 to confirm the mechanism.
- **A near-tie** (top two within ~20 points) → don't pick; instrument in
  Phase 4 to discriminate.
- **None above ~50%** → report the ambiguity and ask the user; don't edit on a
  coin-flip.

### Phase 4 — Instrument & localize (bisect, don't stare)

- **Bisect the pipeline** — check `tp_model`, then the EF, then the `emi_list`,
  then the summary; the bug is upstream or downstream of each. Repeat inside
  the culprit function.
- **Bisect history** — if it "worked yesterday", compare with the last good
  commit (`git bisect` is fine; it doesn't discard work).
- **Instrument with diagnostic primitives** — at each stage: `nrow()`;
  `anyNA()` and `summary()` of `speed`, `dist`, EF and emission columns;
  `units::deparse_unit()` of each unit column; `sum(fleet_composition)`;
  the rows of the EF table matched by the inputs; `sf::st_crs()`;
  `data.table::address()` to check whether a table is the caller's object.
  **The stage where a count jumps or drops, an `NA` appears, or a unit changes
  or disappears is the culprit stage.**

End Phase 4 with a one-sentence root cause naming the exact line and mechanism.

### Phase 5 — Fix, verify, guard

**Confidence gate:** don't apply a fix unless the root cause is named **and**
its mechanism is explicit. A near-tie in Phase 3b means behaving as `--no-fix`.

Unless `--no-fix` is set:

1. Apply the **minimal** fix at the root cause, following
   `.claude/rules/r-package-conventions.md` (copy before in-place updates,
   preserve units, `cli::cli_abort()` (class `gtfs2emis_error`) naming the bad value for new errors (conventions A4), EF
   databases changed only via `data-raw/`).
2. Re-run the MWE → confirm actual == expected; if the worker path changed,
   install and compare `parallel = FALSE` **and** `parallel = TRUE, ncores = 2`.
3. **Add one targeted regression test** in `tests/testthat/test_<fn>.R` that
   reproduces the MWE on a bundled fixture and fails without the fix.
4. Run `devtools::test(filter = "<fn>")` and Gate 1 from
   `.claude/rules/quality-gates.md`. If hard-coded expected values in other
   tests move, re-derive them from the source table/equation and justify them;
   don't paste new output.

| Bug class | Typical regression test |
|---|---|
| By-reference mutation | `old <- data.table::copy(x)`; call; `expect_equal(old, x)` |
| Absent EF combination | `expect_error(ef_europe_emep(..., euro = "III", tech = "SCR"), "tech")` |
| Known EF value | `expect_equal(as.numeric(ef$EF[1]), <hand value>, tolerance = 1e-6)`, source cited in a comment |
| Units | `expect_s3_class(<col>, "units")`; `expect_equal(units::deparse_unit(<col>), "g/km")` |
| Parallel divergence | `expect_equal(emission_model(..., parallel = FALSE), emission_model(..., parallel = TRUE, ncores = 2))` |

With `--no-fix`, stop after the root cause is named and report it.

## Worked example (hypothetical)

Suppose a user reports `NA` emission factors for one row of a Dublin fleet. (This
illustrates the method; it is not a known gtfs2emis bug. Verify against the
current code before acting.)

```r
# Phase 0: expected: a veh_type/euro/tech combination absent from the EMEP
# table is an error naming it; actual: each value passes its own
# checkmate::assert_choice(), the combination matches no row, and the
# function returns NA that the summaries silently carry.

# Phase 2: MWE straight on the EF function, no transport model needed
spd <- units::set_units(c(10, 30, 60), "km/h")
ef  <- ef_europe_emep(speed = spd, veh_type = "Ubus Midi <=15 t",
                      euro = "III", pollutant = "CO2", fuel = "D",
                      tech = "SCR")      # hypothetical: no Euro III + SCR row
anyNA(ef$EF)                             # TRUE -> red

# Phase 4: root cause (hypothetical): values are validated one by one, but
# the joint filter on Segment/Euro/Technology returns zero rows, which become
# NA after the speed expansion instead of raising an error.

# Phase 5: after filtering, stop() if nrow() == 0, naming the combination and
# listing the valid tech values for that segment/euro; then test:
test_that("absent EF combination errors", {
  expect_error(ef_europe_emep(speed = spd, veh_type = "Ubus Midi <=15 t",
                              euro = "III", pollutant = "CO2", fuel = "D",
                              tech = "SCR"), "tech")
})
```

Other symptoms the same method handles: `emission_model()` totals that differ
with `parallel = TRUE` because the workers ran an older installed gtfs2emis; or
emissions 1000x too large because a `dist` in metres was treated as km.

## Report

Write a short diagnosis to `quality_reports/diagnoses/YYYY-MM-DD_<slug>.md`
(local, gitignored):

- **Symptom:** expected vs. actual.
- **MWE:** minimal feed/call that reproduces it.
- **Root cause:** exact line and mechanism.
- **Fix:** diff applied (or recommended, with `--no-fix`).
- **Verification:** MWE (both parallel modes if the worker path changed), targeted tests, Gate 1 results.
- **Regression test:** the test added.

Plus a chat summary leading with the one-line root cause.

## Exit behavior

| Outcome | Action |
|---|---|
| Root cause named, fix applied, re-verified | report root cause + diff + test |
| `--no-fix` | stop at a named root cause; write the report; no source edits |
| Phase 0 blocked (no expected/actual) | ask for the expected result |
| Phase 1 blocked (can't reproduce) | report the nondeterminism as the finding + how to make it deterministic |
| Phase 3b near-tie / <50% | report competing hypotheses; ask; no fix |

## What this skill does NOT do

- **Build test infrastructure** — it adds one regression test for *this* bug.
- **Fix unrelated issues** it notices — those go to the backlog.
- **Commit** — that is [`/g2e-commit`](../g2e-commit/SKILL.md)'s job.
