---
paths:
  - "R/**"
  - "tests/**"
  - "vignettes/**"
  - "data-raw/**"
  - "README.md"
  - "DESCRIPTION"
  - "NEWS.md"
  - "_pkgdown.yml"
---

# Quality gates (gtfs2emis)

Gates are **pass/fail checks**, not scores. A task is "done" only when the gate
for its checkpoint passes and the output has actually been seen. "Should work"
doesn't count.

## Gate 1: Task done / commit

All must hold for the files touched:

| Check | Command | Pass |
|---|---|---|
| Docs regenerated | `Rscript -e "devtools::document()"` then `git diff --stat man/ NAMESPACE DESCRIPTION` | No unexpected content drift (use `git diff`, not `git status`: `core.autocrlf=true` can rewrite line endings only); intended changes staged with the source |
| Targeted tests | `Rscript -e "devtools::test(filter = '<fn>')"` for every touched function (files are `test_<fn>.R`) | 0 failures, 0 new warnings |
| Units / known values | for EF or emission math changes: a hand-checked value against the source table/equation | Matches within tolerance |
| Parallel parity | if `transport_model()`/`emission_model()` worker code changed: run with `parallel = FALSE` and `parallel = TRUE, ncores = 2` (install the package first) | Identical results |
| Data | if `data/*.rda` changed | Rebuilt by the `data-raw/` script; `R/data.R` matches the columns |
| Style | read the diff against the surrounding code | Matches the file (conventions A5) |
| NEWS | user-facing change | Bullet under the development-version heading (conventions A9) |
| pkgdown index | if an `@export` was added or removed: `Rscript -e "pkgdown::check_pkgdown()"` | No missing or stale topics (`_pkgdown.yml` at the root) |
| Staging hygiene | `git diff --cached --name-only` | No `.rds`/`.RData`/`.Rhistory`/stray outputs; no workflow files except `CLAUDE.md` and `.claude/rules/` |
| Conventions | `.claude/rules/r-package-conventions.md` checklist | All items hold |

## Gate 2: Pull request

Gate 1, plus:

| Check | Command | Pass |
|---|---|---|
| Full suite | `Rscript -e "devtools::test()"` | 0 failures |
| CRAN check | `Rscript -e "devtools::check(document = FALSE, args = '--as-cran')"` (background) | 0 errors, 0 warnings; each NOTE triaged (pre-existing vs new) |
| Vignettes | built by the check above | Render without error, ≤ 2 cores |
| Review loop | parallel review lenses (`orchestrator-protocol.md`) | Converged: 0 open CRITICAL/MAJOR |
| Package review | `r-package-reviewer` agent on changed files | 0 CRITICAL/MAJOR |

## Gate 3: Release (maintainer-driven)

Gate 2, plus `/g2e-package-check` (full report), `devtools::check_win_devel()`
and/or R-hub, `cran-comments.md` updated, and `_pkgdown.yml` covering all
exports. gtfs2emis depends on {gtfs2gps} (and Suggests {gtfstools}): check
against their current CRAN versions and, when relevant, their development
versions. Claude prepares; the maintainer bumps the version and submits.

## Overrides

A gate may be skipped only on an explicit user instruction ("commit anyway"),
and the reason is recorded in the commit body and the session log. Never use
`git commit --no-verify`.

## Pre-existing failures

If a gate fails for reasons unrelated to the change, don't fix it as a drive-by.
Report it, confirm it also fails on `master`, and add it to the backlog
(`quality_reports/specs/`).
