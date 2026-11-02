# CLAUDE.md — gtfs2emis

**gtfs2emis** is an R package that estimates public transport emissions
from GTFS data with a bottom-up model.
[`transport_model()`](https://ipeagit.github.io/gtfs2emis/dev/reference/transport_model.md)
turns a GTFS feed into stop-to-stop road segments with speeds and
distances (via {gtfs2gps}). The `ef_*()` functions return emission
factors from four sources: Europe EMEP/EEA, Brazil CETESB, USA MOVES and
USA EMFAC, plus scaled-Euro local factors.
[`emission_model()`](https://ipeagit.github.io/gtfs2emis/dev/reference/emission_model.md)
combines segments, fleet data and emission factors. The `emis_*()`
helpers summarise the result by time, vehicle and pollutant, or on a
spatial grid. It is built on `data.table`, `sf`, `units`, `checkmate`,
`terra` and `future`/`furrr`. Published on CRAN; developed by Ipea
(ipeaGIT). Maintainer (cre): Joao Bazzo; authors include Rafael H. M.
Pereira and Pedro R. Andrade. License MIT. Docs:
<https://ipea.github.io/gtfs2emis/> (DESCRIPTION still points to the
dead `ipeagit` host; audit item \#30). Method paper: Vieira, Pereira &
Andrade (2022), <doi:10.31219/osf.io/8m2cy>. Default branch: `master`.

------------------------------------------------------------------------

## Core principles

- **Correct emissions first.** Emission factors must match their source
  (EMEP/EEA, CETESB, MOVES, EMFAC), within each source’s speed validity
  range. Units (km/h, km, g/km, g) are part of the API. An unknown
  pollutant/vehicle/Euro/model-year combination is an error, never a
  silent `NA`.
- **Never surprise the caller.** Functions don’t modify the user’s GTFS,
  `tp_model`, fleet data or `emi_list`
  ([`data.table::copy()`](https://rdrr.io/pkg/data.table/man/copy.html)).
- **Parallel = sequential.**
  [`transport_model()`](https://ipeagit.github.io/gtfs2emis/dev/reference/transport_model.md)
  and
  [`emission_model()`](https://ipeagit.github.io/gtfs2emis/dev/reference/emission_model.md)
  must give the same result with `parallel = TRUE` and
  `parallel = FALSE`.
- **CRAN-ready at all times.** `R CMD check --as-cran`: 0 errors, 0
  warnings. Examples and vignettes use ≤ 2 cores and write only to
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).
- **Plan first.** Enter plan mode before non-trivial tasks. Every plan
  is reviewed by two adversarial agents that improve it and make it
  simpler, with as little code change as possible. Present the plan only
  when both agents agree (max 3 rounds, then escalate the disagreement).
  Plans live in `quality_reports/plans/`.
- **Verify after.** Every task ends with the gates below, not with
  “should work”.
- **Learn from corrections.** Log `[LEARN:category] wrong → right` in
  `MEMORY.md`.
- **Code style.** Use `package::function()` in new code (the data.table
  operators already imported are the exception). Otherwise match the
  style of the file you are editing.

Conventions are in
[`.claude/rules/r-package-conventions.md`](https://ipeagit.github.io/gtfs2emis/dev/.claude/rules/r-package-conventions.md);
gates are in
[`.claude/rules/quality-gates.md`](https://ipeagit.github.io/gtfs2emis/dev/.claude/rules/quality-gates.md).

------------------------------------------------------------------------

## Repository map

    gtfs2emis/
    ├── DESCRIPTION, NAMESPACE        # NAMESPACE is roxygen-generated; never hand-edit
    ├── R/
    │   ├── transport_model.R         # GTFS → sf segments (gtfs2gps), parallel/output_path
    │   ├── emission_model.R          # tp_model + fleet + EF → emi_list, parallel
    │   ├── ef_europe_emep.R, ef_brazil_cetesb.R, ef_usa_moves.R, ef_usa_emfac.R, ef_scaled_euro.R
    │   ├── emi_europe_emep_wear.R    # non-exhaust (tyre, brake, road wear)
    │   ├── slope_class_europe_emep.R # road slope from a DEM (terra)
    │   ├── emis_summary.R, emis_to_dt.R, emis_grid.R   # post-processing
    │   ├── multiply_ef.R, fuel_correction.R            # internal helpers
    │   ├── data.R                    # docs for the EF databases
    │   ├── utils.R                   # @importFrom, globalVariables
    │   └── _pkgdown.yml              # stray copy; the root _pkgdown.yml is authoritative
    ├── data/*.rda                    # EF databases (ef_*_db), built by data-raw/*.R
    ├── data-raw/                     # scripts that build data/; Rbuildignored
    ├── tests/testthat/               # test_<function>.R; setup.R builds shared fixtures (needs gtfstools)
    ├── inst/extdata/                 # irl_dub_*, bra_cur_* (+ srtm.tif), usa_det_* GTFS + fleet fixtures
    ├── vignettes/                    # intro, emission factors, fleet data, non-exhaust
    ├── README.md                     # hand-written (no README.Rmd)
    ├── NEWS.md, cran-comments.md, _pkgdown.yml
    └── .github/workflows/            # R-CMD-check (+ CRAN variant), test-coverage, pkgdown

Exports: `transport_model` · `emission_model` · `ef_europe_emep`,
`ef_brazil_cetesb`, `ef_usa_moves`, `ef_usa_emfac`, `ef_scaled_euro` ·
`emi_europe_emep_wear` · `slope_class_europe_emep` · `emis_summary`,
`emis_to_dt`, `emis_grid`.

Local-only workflow files (gitignored and Rbuildignored): `MEMORY.md`,
`quality_reports/`, `templates/`, and everything in `.claude/` except
`rules/`.

------------------------------------------------------------------------

## Commands

``` r

devtools::load_all()
devtools::document()                          # regenerate man/, NAMESPACE
devtools::test()                              # full suite (setup.R needs gtfstools)
devtools::test(filter = "ef_europe_emep")     # matches tests/testthat/test_ef_europe_emep.R
devtools::check(document = FALSE, args = "--as-cran")   # run in background
pkgdown::build_site()
covr::package_coverage()
```

- `.Rbuildignore` excludes `tests/`, so tests do **not** run on CRAN.
  They run locally and on GitHub Actions.
- `core.autocrlf=true`: regenerated files can show line-ending-only
  diffs. Check drift with `git diff`, not `git status`.
- Parallel workers load the **installed** gtfs2emis, not `load_all()`
  code. Install before testing a changed worker path.

------------------------------------------------------------------------

## Quality gates (summary)

| Checkpoint | Must hold |
|----|----|
| Commit | `document()` produces no content drift; tests for touched functions pass; known-value check for EF/emission math changes; parallel/sequential parity if worker code changed; `NEWS.md` entry for user-facing changes |
| PR | Full `test()` passes; `check(--as-cran)` gives 0 errors / 0 warnings, NOTEs triaged; review loop converged; `r-package-reviewer` 0 CRITICAL/MAJOR |
| Release | `/g2e-package-check`; win-builder + R-hub; compatibility with current {gtfs2gps}; `cran-comments.md` updated |

Never use `--no-verify`. Details: `.claude/rules/quality-gates.md`.

------------------------------------------------------------------------

## Skills and agents

These are local to the maintainer’s Claude setup and are not in git. In
a fresh clone, follow the rules in `.claude/rules/` directly.

Project skills carry a `g2e-` prefix so user-level skills with the same
base name can’t shadow them. **In this repo, always use the `g2e-`
version:** use `/g2e-commit`, never a generic `/commit` that merges to
`master`. Where user-level rules conflict with `.claude/rules/`, the
project rules win.

- `/g2e-package-check`: document, test, check `--as-cran`, triage,
  reviewer report.
- `/g2e-commit`: Gate 1, then branch and commit. Push and PR only when
  asked, after Gate 2. **Merging to `master` only on explicit request.**
- `/g2e-diagnose`: root-cause a failing test or wrong emission result.
- `/g2e-checkpoint`, `/g2e-compress-session`, `/context-status`: session
  state.
- `/g2e-learn`: turn a session discovery into a reusable skill.
- Agent `r-package-reviewer`: read-only CRAN and convention review of
  package source.

------------------------------------------------------------------------

## Working mode

1.  **Plan:** for non-trivial tasks, enter plan mode, explore, ask only
    about real decisions, pass the adversarial plan review, and get
    approval.
2.  **Execute (contractor mode):** after approval, work autonomously
    through implement → verify → parallel review → fix, looping until
    reviews come back dry (see
    `.claude/rules/orchestrator-protocol.md`). Come back only for
    ambiguity or a decision that belongs to the user.
3.  **Report:** summarise what changed, gate results, open questions;
    log the session.

No commits, pushes, PRs, merges, version bumps or `.github/workflows/`
changes without an explicit request. Never hand-edit generated files
(`NAMESPACE`, `man/*.Rd`) or `data/*.rda` (rebuild via `data-raw/`).
