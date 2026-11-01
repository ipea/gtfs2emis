# Workflow Quick Reference (gtfs2emis)

**Model:** contractor. You direct; Claude plans, gets approval, then
orchestrates autonomously.

---

## The loop

```
Your instruction
    ↓
[PLAN]          plan mode: explore → ask real decisions only → draft
    ↓
[IMPROVE PLAN]  two adversarial agents (Minimalist + Skeptic) challenge it
    ↓            until both approve (max 3 rounds, then you decide):
    ↓            simpler, minimal code change, correct
[APPROVE]       you review the plan (ExitPlanMode)
    ↓
[EXECUTE]       implement → Gate 1 → parallel review → fix → loop until dry
    ↓
[REPORT]        what changed, gate results, deferred items, questions
    ↓
[/g2e-commit]    only when you ask: branch → commit; push/PR on request after Gate 2;
               merge only on explicit request
```

Rules: `.claude/rules/plan-first-workflow.md`, `orchestrator-protocol.md`,
`quality-gates.md`, `r-package-conventions.md`.

---

## I ask you when

- **API/behaviour forks:** argument names, defaults, breaking changes,
  deprecations
- **New dependency** (Imports or Suggests)
- **Spec ambiguity:** an EF source (EMEP/EEA, CETESB, MOVES, EMFAC) allows
  several readings, or an output's columns/units would change
- **Scope:** "also fix Y while here?" (default: no, it goes to the backlog)
- **Reviewers disagree** on user-facing behaviour, or a finding survives two
  fix rounds
- **A gate can't pass** without changing the plan

## I just execute when

- The plan is approved and the step is unambiguous
- Running gates (document, tests, lint, check) and fixing what they surface
  within scope
- Session logs, `[LEARN]` entries, plan status updates

## Never without explicit request

Commits, pushes, PRs, merges, version bumps, CRAN submission, edits to
generated files, changes to `.github/workflows/`.

---

## Gates (pass/fail)

| Checkpoint | Must pass |
|---|---|
| Task done / commit | `document()` no drift (`man/`, `NAMESPACE`, `DESCRIPTION`) · targeted tests · known value for EF/emission math · parallel parity if worker path changed · NEWS for user-facing |
| PR | full tests · `check --as-cran` 0E/0W · review loop converged · `r-package-reviewer` OK |
| Release | `/g2e-package-check` · win-devel / R-hub · gtfs2gps / gtfstools compatibility · `cran-comments.md` |

---

## Non-negotiables

- `package::function()` in new code (existing data.table `@importFrom`
  operators excepted)
- Never modify the caller's GTFS, `tp_model`, fleet data or `emi_list`
  (`copy()` first)
- Units are part of the API: km/h, km or m as documented, g/km, g
- EF lookups error on unknown combinations, never return `NA` silently;
  `data/*.rda` changed only via `data-raw/`
- Same result with `parallel = FALSE` and `TRUE` (install first: workers load
  the installed package); no `<<-` in workers
- ≤ 2 cores and `tempdir()` only in tests/examples/vignettes
- Conditions via cli (`cli::cli_abort/cli_warn/cli_inform`, internal `assert_*()` wrappers); errors classed `gtfs2emis_error` (conventions A4)
- Speed claims need `bench::mark` with equal results
- Tests (`test_<fn>.R`): "doesn't change input data", units, known EF values
  with the source cited; fixtures `irl_dub` (EMEP), `bra_cur` (CETESB, slope),
  `usa_det` (MOVES/EMFAC)

## Preferences

**Reporting:** concise bullets; details on request.
**Session logs:** always (post-plan, incremental, end-of-session).
**Early sessions:** extra check-ins at phase boundaries while the workflow is
new.
