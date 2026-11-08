---
paths:
  - "R/**/*.R"
  - "tests/**/*.R"
  - "man/**"
  - "vignettes/**"
  - "data-raw/**"
  - "README.md"
  - "DESCRIPTION"
  - "NAMESPACE"
  - "NEWS.md"
  - "_pkgdown.yml"
---

# gtfs2emis package conventions

**Standard:** a CRAN-ready package that gives correct emission estimates.
`R CMD check --as-cran` returns 0 errors, 0 warnings, and only explained notes.
New code reads like the code around it.

Part A describes how gtfs2emis is written today (checked against the source on
2026-10-12). Items tagged **[NEW]** are decisions for new or modified code
only. Never apply them to untouched code as drive-bys. Part B is the general
CRAN standard. When they conflict, Part A wins; flag the conflict in the plan.

---

# Part A: gtfs2emis house style

## A1. Namespacing

- **Call dependencies as `package::function()`**: `data.table::`, `sf::`,
  `sfheaders::`, `units::`, `gtfs2gps::`, `future::`, `furrr::`,
  `parallelly::`, `terra::`, `checkmate::`.
- **Existing `@importFrom`** (in `R/utils.R`): data.table `:=`, `.SD`, `.I`,
  `.GRP`, `%like%`, `setDT`; `methods::is`. Don't add new `@importFrom`
  without a plan.
- Never use `library()`/`require()` in `R/`. Suggested packages (`gtfstools`,
  `ggplot2`, `lwgeom`, `progressr`) are guarded with
  `requireNamespace("pkg", quietly = TRUE)`.
- Column names used with non-standard evaluation go in a
  `utils::globalVariables(c(...))` call in `R/utils.R`. Append new names at the
  end and check for duplicates first.

## A2. The pipeline and its objects

```
GTFS ──transport_model()──► tp_model (sf LINESTRING per stop-to-stop segment,
                             with dist, speed, trip/time columns)
fleet data + ef_*()  ─────► EF (units g/km, one column per fleet type)
tp_model + fleet + EF ──emission_model()──► emi_list (list: tp_model, emi, fleet_composition, ...)
emi_list ──emis_summary() / emis_to_dt() / emis_grid()──► tables / sf grids
```

| Object | Notes |
|---|---|
| `tp_model` | `sf` from `transport_model()` (wraps `gtfs2gps::gtfs2gps()` + `gtfs2gps::gps_as_sflinestring()`); `slope_class_europe_emep()` adds a slope column |
| fleet data | `data.frame` with `veh_type`, `fuel`, `fleet_composition` (sums to 1), plus `euro`/`tech` (EMEP, scaled Euro) or `model_year`/`reference_year` (CETESB, MOVES, EMFAC) |
| EF | `units` g/km; speed-dependent models (EMEP, MOVES, scaled Euro) return one value per speed |
| `emi_list` | output of `emission_model()`; also what `emi_europe_emep_wear()` feeds into the summaries |

- **Units are part of the API.** Speeds are km/h, distances km or m as
  documented, EFs g/km, emissions g. Use the `units` package; when computing,
  drop units, compute, and restore them before returning. Numeric user inputs
  for speed are interpreted as km/h and may also be `units` objects.
- **EF lookups must not silently return `NA` or the wrong row.** A
  pollutant/veh_type/euro/model_year combination not in the database is an
  error that names the bad value and lists the valid ones.
- **Speed validity ranges** (EMEP and MOVES tables) are applied explicitly;
  document what happens outside them.
- **EF databases** live in `data/*.rda` and are built by `data-raw/*.R`.
  Never edit an `.rda` by hand; change the `data-raw` script and rebuild.
  `R/data.R` documents each database and must match its real columns.
- **Validation:** most exported functions already use `checkmate::assert_*`.
  New or modified arguments do too: `checkmate::assert_choice()` /
  `assert_subset()` for enumerations.

## A3. data.table and parallelism

- **Never modify the caller's objects.** Any `:=`/`set*()`/`setDT()` on a table
  reachable from user input (GTFS, `tp_model`, fleet data, `emi_list`) must be
  preceded by `data.table::copy()` (as `transport_model()` and `emis_grid()`
  do).
- Use keyed / `on =` joins and `by =` grouping. No new row-wise loops.
- **Parallelism:** `transport_model()` and `emission_model()` take
  `ncores` (default 2; `parallel` is deprecated). `transport_model()` passes
  it to {gtfs2gps} as threads; `emission_model()`, for a folder `tp_model`,
  sets `future::plan("multisession", workers = ncores)`, restores the
  previous plan with `on.exit()`, and uses `furrr::future_map()`.
  - Worker code runs in separate R processes: no `<<-`; return values.
  - Under `load_all()`, workers load the **installed** gtfs2emis, so install
    before testing a changed worker path.
  - A worker-path change must give **identical results** with
    `ncores = 1` and `ncores = 2` (Gate 1).
  - Never use more than 2 workers in tests, examples or vignettes.
- `transport_model(output_path = )` writes files: only to the user's path or
  `tempdir()`.

## A4. Messages, warnings and errors (cli)

**Decision (2026-10-13, maintainer):** every user-facing condition goes through
`cli` (`cli` and `rlang` are in Imports). Plan: `quality_reports/plans/2026-10-12_cli-conditions.md`.

- **Input checks** keep checkmate semantics through the internal wrappers in
  `R/conditions.R`: write `assert_numeric(x, ...)` (no `checkmate::` prefix),
  and `assert_checks(check_a, check_b, combine = "or", .var.name = "x")` for
  combinations. They throw `cli_abort()` with class `gtfs2emis_error`.
- **Other conditions:** `cli::cli_abort()`, `cli::cli_warn()`,
  `cli::cli_inform()`. Never use base `stop()`/`warning()`/`message()`,
  `print()` or `cat()`.
- **Classes:** every error has `class = "gtfs2emis_error"`. A missing EF
  combination also has `gtfs2emis_missing_ef`. Add a sub-class only when users
  or tests need to catch it.
- **Brace safety:** user values and checkmate messages are interpolated
  (`{.val {x}}`, `"{msg}"`), never pasted into the format string. Never put a
  dotted name such as `{.var.name}` inside `{}`.
- **Caller header:** inside `lapply()`/closures, capture
  `call <- rlang::current_env()` at the top of the exported function and pass
  `call = call` to every `cli_abort()`/`assert_*()` there (otherwise the
  header says `FUN()`).
- **`.var.name`:** give it explicitly when the checked value is a loop variable
  (`for (i in pollutant) assert_choice(i, ..., .var.name = "pollutant")`) or a
  literal/expression (`assert_choice("emi", names(emi_list), .var.name = "emi_list")`).
- Informative output respects `quiet` (`cli_inform()` is a message condition,
  so `suppressMessages()` still works).

## A5. Style

- 2-space indent, `<-`, snake_case, explicit `return()` at the end of functions.
- The code base often writes `if(`/`function(` without a space and puts
  arguments on new lines with **leading commas**:
  ```r
  emission_model(  tp_model = tp_model
                 , ef_model = "ef_europe_emep"
                 , fleet_data = fleet_data
                 , pollutant = c("CO2", "PM10"))
  ```
  Match the file you are editing; don't reformat untouched code.
- There is no `.lintr`; lintr output is advisory. Keep new lines ≲ 100 columns.

## A6. Documentation (roxygen2, markdown ON)

- `Roxygen: list(markdown = TRUE)`: use backticks and `[fun()]` links.
- Every export documents all `@param`s (type, units, allowed values, default),
  `@return` (class, columns, units), `@family`/`@seealso` where useful, and
  `@examples`.
- **Examples** use the bundled fixtures and stay small: one shape of
  `irl_dub_gtfs.zip`, `ncores = 1`. Slow examples go in `\donttest{}`,
  never `\dontrun{}`.
- Internal helpers (`multiply_ef()`, `fuel_correction()`): `@noRd` or
  `@keywords internal`, matching the file.
- New exports go into the `reference:` index of `_pkgdown.yml` (there is also
  a stray `R/_pkgdown.yml`; the root one is authoritative).
- Never hand-edit `NAMESPACE` or `man/*.Rd`; run `devtools::document()`.
  `README.md` is hand-written (no `README.Rmd`).

## A7. Tests (testthat)

- Files are `tests/testthat/test_<function>.R` (**underscore**).
  `tests/testthat/setup.R` builds shared fixtures (`tp_model_irl`,
  `fleet_data_europe`, `fleet_data_cetesb`, `fleet_data_usa`) and needs
  `gtfstools`.
- **`.Rbuildignore` excludes `^tests$`** (audit item #26), so tests do not
  run in R CMD check or on CRAN. Only the covr `test-coverage` workflow runs
  them. Still keep them ≤ 2 cores and write only
  to `tempdir()`.
- Fixtures in `inst/extdata/`: `irl_dub_gtfs.zip` + `irl_dub_fleet.txt`
  (EMEP), `bra_cur_gtfs.zip` + `bra_cur_fleet.txt` + `bra_cur-srtm.tif`
  (CETESB, slope), `usa_det_gtfs.zip` + `usa_det_fleet.txt` (MOVES/EMFAC).
- **New or modified functions** need at least:
  - an invalid-argument error test
  - returned class, columns and **units**
  - a **known-value test** for EF functions (a value checked by hand against
    the source table/equation, with the source cited in a comment)
  - "doesn't change input data" when the function takes a data.table/sf
  - `ncores = 1` vs `ncores = 2` parity if the worker path changed
- When an algorithm change legitimately moves pinned values, re-derive them
  and explain the change in the plan; never paste new output blindly.

## A8. Performance

A claimed speed-up needs `bench::mark()` on a fixture with equal results
(`all.equal()`) recorded in the plan or session log. Don't add a hard
dependency without a plan.

## A9. NEWS.md

One `# gtfs2emis X.Y.Z` section per release with `-` bullets. Add a
`# gtfs2emis (development version)` heading if absent; the maintainer renames
it at release. Credit external contributors and reference issues (`#123`).

## A10. Figures (vignettes, README, pkgdown)

- **[NEW]** For new or modified figures: one consistent theme, a
  colour-blind-safe palette (viridis / Okabe-Ito), labelled axes with units,
  fixed `fig.width`/`fig.height`/`dpi`, maps in EPSG 4326 or a stated projected
  CRS. Plotting packages stay in Suggests.

---

# Part B: general CRAN standard

- **DESCRIPTION:** `Imports` for code in `R/`, `Suggests` for
  tests/vignettes/optional paths, `Depends` only for the R version. Version
  floors only when a feature requires them (if `|>` is used in `R/`,
  `Depends: R (>= 4.1)` is required; DESCRIPTION says `R (>= 3.6)`).
- **Red flags:**

| Red flag | Do instead |
|---|---|
| `library()`/`require()` in `R/` | `pkg::fun()` |
| Writing outside `tempdir()` | `tempdir()` or user-supplied `output_path` |
| `<<-` | Return values |
| `options()`/`future::plan()` changed, not restored | `on.exit(..., add = TRUE)` |
| More than 2 cores in tests/examples/vignettes | `ncores = 1` or `ncores = 2` |
| `T`/`F` | `TRUE`/`FALSE` |
| Unvalidated enumerated arg | `checkmate::assert_choice()` |
| `==` on doubles or `units` vs numeric | tolerance / `units::set_units()` |
| EF lookup returns `NA` silently | error naming the invalid value |

- **Versioning:** `X.Y.Z`; dev versions append `.9000`. The maintainer bumps
  release versions; Claude never does.

## Checklist (new or modified code)

```
[ ] pkg::fun() everywhere (except the existing data.table @importFrom operators)
[ ] input data not modified (copy()); test proves it
[ ] new/changed args validated with checkmate
[ ] units correct and preserved (km/h, km/m, g/km, g)
[ ] EF lookups error on unknown combinations; known-value test cites the source
[ ] worker path: identical results ncores = 1 vs 2
[ ] ≤ 2 cores and tempdir() only in tests/examples/vignettes
[ ] conditions via cli / internal assert_* wrappers (A4); errors classed gtfs2emis_error
[ ] style matches the file (leading commas, explicit return())
[ ] roxygen complete (params with units, return with columns/units, examples)
[ ] devtools::document() run; no hand edits to NAMESPACE / man
[ ] data/*.rda changed only via data-raw/ scripts
[ ] NEWS.md bullet for user-facing changes
```

## Cross-references

- [`quality-gates.md`](quality-gates.md): when each check must pass.
- `.claude/agents/r-package-reviewer.md` enforces this rule (local only; in a
  fresh clone, apply the checklist manually).
