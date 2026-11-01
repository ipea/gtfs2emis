# gtfs2emis 0.1.2: package audit (FINAL, after adversarial verification)

**Date:** 2026-10-12

**Environment:**
- Windows 11, R 4.5.1.
- The package was installed from the `git archive` tarball (HEAD 99204aa) into an isolated library, so the repo was not touched.
- Two gtfs2gps versions were tested: 2.1.4.9000 (dev) and **2.1-4 (CRAN, in a separate library)**.
- gtfstools 1.4.0. Tests were run with testthat via `test_dir()`.

**Process:**
1. Four independent auditors each covered one area: core pipeline (PIPE), emission factors (EF), documentation (DOC), and package/tests/CRAN (PKG). Together they raised 97 raw findings.
2. These were deduplicated into a draft (`2026-10-12_package-audit_draft.md`).
3. An adversarial reviewer then re-verified each finding, re-running the CRITICAL and MAJOR ones.
4. Original auditor IDs are kept in brackets for traceability.

**Verdict tags:** **CONF** = reproduced, or the code unambiguously shows it. **PLAUS** = the code supports it but it was not reproduced. **OVER** = real, but the severity was changed.

**Severity:** **CRITICAL** = wrong numbers or a crash in a documented, common workflow. **MAJOR** = wrong numbers in edge cases, silent bad input, misleading docs, or a weak test gate. **MINOR** = robustness, clarity, hygiene.

## Executive summary

- **Issue count:** 7 CRITICAL, 24 MAJOR (items 8–31; item 31 groups 7 doc fixes), plus a compact MINOR table of about 25 items.
- **Wrong numbers:**
  - MOVES gives wrong emission factors for mixed-fuel fleets (#3).
  - CNG FC and CO2 are about 18× too low (#4).
  - Tyre wear gives axle counts to the wrong vehicles (#7).
  - Slopes steeper than +7% are classed as steep downhill (#2).
- **Crashes:**
  - The whole `heightfile` (slope) workflow is broken (#1).
  - `emis_grid()` crashes whenever two vehicles share a Euro stage or model year, which is almost every real Brazilian fleet (#5).
  - EMEP `FC` crashes for diesel Euro I, II, III and V (#6).
- **Test gate is only partly working:**
  - `^tests$` in `.Rbuildignore` means R CMD check and CRAN never run the tests.
  - The covr workflow does run them, and it is green.
  - Value assertions are almost absent, so a green run says little.
- **Fix first:** #1–#7, then turn tests on in R CMD check with known-value tests (#26–#29).

---

## CRITICAL

**1. The `heightfile` / slope workflow crashes, and loses columns when it doesn't crash — CRITICAL, CONF** [B1, B2, B3, B5, B10; PIPE-02/03/04, EF-02/03, DOC-08/27]

Where:
- `R/ef_europe_emep.R:230-305`: per-slope lookup.
- `R/slope_class_europe_emep.R`: the endpoints are grouped `by = stop_sequence` only, and the table is rebuilt from a hard-coded column list.
- `R/ef_scaled_euro.R`: SDC call.

Why it matters: any realistic use of `heightfile` hits one of these.
- (a) EMEP errors with "NAs are not allowed in subscripted assignments" whenever a slope class repeats. `slope=c(0,0.02,0)` fails; `c(0,0.02)` works.
- (b) With more than one shape it fails with "replacement has 6 rows, data has 19".
- (c) The output drops `timestamp`, so `emis_summary(by="time")` and time-resolved `emis_grid()` fail.
- (d) `ef_scaled_euro` fails for any `slope` longer than 1, even `c(0,0)`, so `ef_brazil_scaled_euro` + `heightfile` always fails.
- (e) `terra::SpatRaster` is rejected. Only `raster::RasterLayer` (not a dependency) or a path works.

Fix:
- (a) Look up the EF once per `unique(slope, load)` and map back with `match()`.
- (b, c) Take endpoint heights per row with `sf::st_startpoint()`/`st_endpoint()`, and add `slope_class` to the existing table instead of rebuilding it.
- (d) Evaluate the SDC reference at `slope = 0` (or `rep(SDC, length(slope))`) and document which.
- (e) Accept `SpatRaster`.
- Add a test with 2 shapes and repeated, mixed slopes.

**2. Slopes above +7% are classed as -0.06 (steep downhill) — CRITICAL, CONF** [A1; PIPE-01, DOC-18]
- **Where:** `R/slope_class_europe_emep.R` (`fcase`), and the roxygen table.
- **Why it matters:** the slope classes in the database are symmetric (-0.06…+0.06), so the steepest climbs get the lowest-emission EF. Today this is hidden by #1; it becomes live as soon as #1 is fixed.
- **Fix:** `slope > 0.070, 0.06` in both the code and the doc. Add the `|---|---|` header row so the Rd table renders.

**3. MOVES filters on the `fuel` argument instead of the database column — CRITICAL, CONF** [A2; EF-04]
- **Where:** `R/ef_usa_moves.R`, `fuel %in% tmp_fuel[j]`. The database column is `fuel_type`.
- **Why it matters:** mixed-fuel fleets get silently wrong EFs. `fuel=c("D","CNG")` (MY2015, ref 2020, 20 km/h) gives CO 13.42/11.75 g/km. The correct values are 1.72 (D) and 20.38 (CNG).
- **Fix:** `fuel_type %in% tmp_fuel[j]`, plus a mixed-fuel known-value test.

**4. CNG FC and CO2 are energy factors (MJ/km) labelled g/km — CRITICAL, CONF** [A3; EF-05]
- **Where:** `data-raw/ef_europe_emep_db.R:221,252-253` → `data/ef_europe_emep_db.rda`.
- **Why it matters:**
  - The CNG FC rows are identical to the EC rows, and CO2 = EC × 3.17, which is the diesel ratio.
  - EEV at 19 km/h gives FC 20.4 and CO2 64.9 "g/km".
  - The values should be about 425 g/km fuel and about 1170 g/km CO2, so the current ones are 18–20× too low.
  - The diesel EC of 14.4 confirms that EC is MJ/km.
- **Fix:**
  - Set CNG FC = EC / LHV_CNG (about 48 MJ/kg).
  - Set CO2 = FC × the CNG carbon ratio (about 2.75), not 3.17.
  - Label EC as MJ/km, or drop it.
  - Rebuild the .rda.

**5. `emis_grid()` crashes when two fleet rows share a Euro stage or model year — CRITICAL, CONF (upgraded from MAJOR)** [B6; PIPE-11, EF-18]
- **Where:** EF and emission column names such as `NOx_Euro_V` and `CO_2015` are not unique per vehicle, so `setnames()` in `R/emis_grid.R` fails with "Some duplicates exist in 'old'".
- **Why it matters:** reproduced with a CETESB fleet of URBAN and MICRO buses, both MY2015. The shipped Curitiba fleet has repeated years, so the Brazilian workflow crashes at the gridding step. `emis_summary()` and `emis_to_dt()` still work.
- **Fix:** add the vehicle index to the column names (`_veh_i`, as the wear code already does), and rename by position in `emis_grid()`.

**6. EMEP `FC` crashes for diesel Euro I, II, III and V because of duplicate database rows — CRITICAL, CONF** [B4 + A10; EF-01, EF-25, EF-12]
- **Where:**
  - `ef_europe_emep_db` has 525 duplicated keys, all for `Pol == "FC"`, diesel, Euro I/II/III/V. The cause is mixed 2007/2013/2019 editions.
  - `switch()` then receives more than one `Function_ID` and errors with "EXPR must be a length 1 vector". CO2 and NOx are unaffected.
  - `data-raw/ef_europe_emep_db.R:591` has a top-level `break()`, so the script cannot rebuild the .rda.
- **Related (MAJOR):** for Euro IV FC/CO2, `ef_europe_emep()` forces `tech = "-"` (a 2007 equation) and claims the SCR row was "not found", but SCR and EGR rows from 2019 exist.
- **Fix:**
  - In data-raw, keep one edition per key (the latest), remove the `break()`, and rebuild.
  - Add a test that the key is unique.
  - Apply the FC/CO2 tech fallback only when `nrow(match) == 0`.

**7. Tyre wear assigns the axle count by set membership, not by row — CRITICAL, CONF** [A4; EF-06, PIPE-14]
- **Where:** `R/emi_europe_emep_wear.R:281`, `n_axle_table[veh %in% tmp_veh_type, n_axle]`. This returns values in table order. Brake and road wear do not use axles.
- **Why it matters:**
  - `c(Artic, Midi)` and `c(Midi, Artic)` give identical results, so the 3-axle Artic gets 2 axles.
  - Per-vehicle tyre PM is off by up to 1.5×.
  - Repeated veh_types are silently recycled.
- **Fix:** `n_axle_table$n_axle[match(tmp_veh_type, n_axle_table$veh)]`.

## MAJOR

| # | Issue [IDs] | Where | Why it matters | Fix |
|---|---|---|---|---|
| 8 | **NA timestamps from `transport_model()` pass through silently.** CONF, also with **CRAN gtfs2gps 2.1-4** [A14, D2; PIPE-15, PKG-01] | `R/transport_model.R`; upstream `gtfs2gps::adjust_speed` | 2 of 19 segments have NA timestamps. `emis_summary(by="time")` creates an `NA` hour holding about 7% of NOx, and time-resolved `emis_grid` stops. The 2 test failures occur only with dev gtfs2gps | Warn (or interpolate) in `transport_model()`; report upstream; make test expectations independent of the NA rows |
| 9 | **`fleet_composition` is not checked to sum to 1.** CONF [A5; PIPE-08] | `R/emission_model.R` | Tripling the fleet rows gives exactly 3× the emissions, with no warning | Assert values in [0,1] and `abs(sum - 1) < 1e-6` |
| 10 | **`reference_year` is documented as a `fleet_data` column but ignored.** CONF, downgraded from CRITICAL [A6; PIPE-10, DOC-02] | `R/emission_model.R` docs and examples; fleet vignette (`calendar_year`) | A column value of 2015 still gives 2020 results (7.98 vs 7.18 g CO). The argument itself works | Remove it from the fleet docs, examples and vignette, or warn when the column is present |
| 11 | **The "detailed" fleet table with `shape_id` is promised but never used.** CONF, downgraded from CRITICAL [A7; DOC-01] | `README.md:100-105`, intro vignette 146-147, fleet vignette 27-28/43 | Users expect per-route allocation but get uniform allocation | Remove the claim, or document "split `tp_model` by shape"; implementing it is a feature |
| 12 | **Fleet vectors are silently truncated or recycled.** CONF [A11; EF-10/11, DOC-14, PIPE-20] | `ef_europe_emep()` (its own example drops a vehicle); `ef_scaled_euro()`; internal `multiply_ef()` | Vehicles silently go missing | Recycle length-1 inputs only, otherwise `stop()`; fix the example |
| 13 | **MOVES and EMFAC ignore speed units.** CONF [A13; EF-09] | `ef_usa_moves.R`, `ef_usa_emfac.R` | 10 m/s gives the same EF as 10 km/h | `units::set_units(speed, "km/h")` before stripping units |
| 14 | **Stale temp files from an aborted run leak into later output.** CONF [A15; PIPE-06, PKG-12] | `R/transport_model.R` (fixed `tempdir()/gps/`; cleanup registered only at the end) | Shapes from a previous run appear in the result | Per-call `tempfile("gps")` plus `on.exit(unlink(dir, recursive = TRUE), add = TRUE)` right after `dir.create` |
| 15 | **`emis_summary()` needs testthat at runtime.** CONF, **new** | `R/emis_summary.R:110`, `checkmate::expect_class()` | `expect_*` loads testthat (Suggests), so it errors for users without testthat | `checkmate::assert_class()` |
| 16 | **Wear `PM1.0` passes validation, then crashes.** CONF [B7; EF-08, DOC-05] | `emi_europe_emep_wear.R` (table uses `'PM1'`) | Crash on a documented option | Rename the table entry to `"PM1.0"` |
| 17 | **`reference_year` ranges don't match the data.** CONF [B8; EF-16, DOC-04/30] | `ef_usa_moves.R` (2010–2020 accepted; data has 2015–2022); EMFAC has no 2018; MOVES error message names `ef_usa_emfac_db` | 2012 passes and then errors with the wrong message; 2021–22 are rejected | Validate against `unique(db$reference_year)`; fix the message; one roxygen template per function |
| 18 | **`process` mixing, and wear with non-EMEP models.** CONF [B9; PIPE-09] | `R/emission_model.R` | `c("hot_exhaust","tyre")` silently returns exhaust only. CETESB + `"tyre"` gives "object 'temp_emis' not found" | `assert_subset(process, …)`; reject mixing, or combine; reject wear for non-EMEP models with a clear message |
| 19 | **Non-mass "pollutants" are returned as g/km.** CONF [A12; EF-13/14, DOC-17] | CETESB `KML` (km/L), `gD/KWH`, `gCO2/KWH`, `FS`; `RCHO`/`ETOH` all-NA; EMEP `SPN23 [#/kWh]` | Output is silently mislabelled | Restrict choices to g/km pollutants (or give proper units); error on all-NA |
| 20 | **`ef_brazil_scaled_euro` requires `tech` but ignores it.** CONF [A8; PIPE-07, DOC-13] | `R/emission_model.R:382-392` | The default "SCR" is always used. The effect is small but silent | Pass `tech = fleet_data$tech` |
| 21 | **`transport_model()` overwrites `ncores`.** CONF [C1; PIPE-05, PKG-07] | `R/transport_model.R:95`, `upper = ncores <- availableCores(omit=1)` | Any user value becomes "all cores but one" | `upper = parallelly::availableCores(omit = 1)` |
| 22 | **`utils::data()` writes the EF databases into `.GlobalEnv`.** CONF [C3; EF-15] | 4 `ef_*` functions | Overwrites user objects; CRAN policy forbids modifying the global environment | Use the lazy data (`gtfs2emis::ef_*_db`) directly |
| 23 | **Wear length checks never fire.** CONF [C4; EF-17] | `emi_europe_emep_wear.R` uses `check_true` instead of `assert_true` | Length mismatches pass; brake with a vector `load` returns extra columns | Use `assert_true`; build brake emissions with `outer()` |
| 24 | **`emis_grid()` uses dense intersects.** PLAUS [C5; PIPE-13] | `st_intersects(sparse = FALSE)` | Runs out of memory at city scale (cells × segments matrix) | `lengths(sf::st_intersects(grid, net)) > 0` |
| 25 | **Dataset docs are wrong.** CONF [DOC-19, EF-24] | `R/data.R` (EMEP has 9913 rows, not 6431; column lists for EMEP/EMFAC/CETESB are wrong) | Misleads users choosing keys | Regenerate `@format` from `str()` |

**Tests and CI**

| # | Issue [IDs] | Fix |
|---|---|---|
| 26 | **`^tests$` in `.Rbuildignore`.** OVER, CRITICAL→MAJOR [D1; PKG-02]. R CMD check (both workflows) and CRAN never run the tests; only the covr workflow does, and it is green (78% coverage). Also, `^test_joao$`/`^tests_rafa$` match the root, not `tests/` | Remove `^tests$`; add `^tests/test_joao$` and `^tests/tests_rafa$`; `skip_on_cran()` the slow setup; `parallel = FALSE` in `setup.R` (it currently uses 11 cores) |
| 27 | **`default_tester()` defaults to the undefined `tp_model_bra`.** CONF [D3; PKG-03]. All 17 `expect_error`s pass for the wrong reason | Valid defaults plus `expect_error(..., regexp = )` |
| 28 | **Undefined fixtures make `expect_error` vacuous.** CONF [D4; PKG-04]. `test_multiply_ef.R` uses `total_fleet`; `test_ef_usa_moves.R` uses `fleet_data_usa$year` | Fix the objects; add `regexp =` |
| 29 | **Almost no value assertions.** CONF [D5, D6; PKG-05/06]. One numeric check is active. There is no `transport_model` test, and `emission_model` is exercised only with EMEP. The slope test uses one trip with all-zero slopes | Known-value tests (`tolerance =`) per `ef_*`; one successful run per `ef_model`; a 2-shape mixed-slope test |

**Documentation (MAJOR)**

| # | Issue [IDs] | Fix |
|---|---|---|
| 30 | **pkgdown URLs return 404.** CONF [DOC-03, PKG-09]. `ipeagit.github.io/gtfs2emis/…` gives 404; `ipea.github.io/gtfs2emis/…` gives 200. `github.com/ipeaGIT/gtfs2emis` still redirects | Replace in DESCRIPTION `URL`/`BugReports`, `_pkgdown.yml`, README, roxygen, NEWS and vignettes with `ipea.github.io/gtfs2emis` and `github.com/ipea/gtfs2emis`. This blocks the next CRAN submission |
| 31 | **Wrong facts in user-facing docs.** CONF (spot-checked); the seven items are listed below | Text fixes |

The seven wrong facts in item 31:
- The fleet vignette swaps the MOVES and EMFAC sources [DOC-10].
- The CETESB inputs are listed as "Age, Fuel, EURO stage" [DOC-11].
- `data(ef_usa_moves)` etc. should be `*_db` [DOC-15].
- `"Coaches Std >18 t"` should be `<=18 t` [DOC-06].
- `emission_model()` @details omits `model_year` [DOC-09].
- `transport_model()` is said to return "data.table sf_linestring"; it returns `sf`/`data.frame` [DOC-21].
- `new_speed = NULL` is described as the feed average; it is actually the per-shape average [DOC-20].

## MINOR (batch)

| ID | Issue | Fix |
|---|---|---|
| A9 (OVER, MAJOR→MINOR) | The brake speed correction is applied above 90 km/h instead of 95 (`emi_europe_emep_wear.R:259`). Buses rarely exceed 90 km/h | `> 95` |
| C2 (OVER, MAJOR→MINOR) | `gtfstools::read_gtfs()` is called unguarded while gtfstools is in Suggests. It is always installed via gtfs2gps | Move to Imports, or `requireNamespace` |
| C6 | `emis_summary(by="time")` drops `segment_vars` | Keep them |
| C7 | `slope`/`load` are not validated against the classes | `assert_subset` |
| C8 | `min/max_speed` are validated as raw numbers; the floors of 2/3 are undocumented | Convert to km/h first; document |
| C9 | The slope calculation assumes `dist` is in km | `units::set_units(dist, "m")` |
| C10 | `emis_grid()` overwrites, then drops, the user's grid `id` | Use a private column |
| C11 | The `emis_grid()` timestamp check is OR-ed | Require the column AND the class |
| C12 | `%like% "HC_"` is unanchored | `paste0("^", i, "_")` |
| C13 | With an sf `tp_model`, `quiet` is ignored and parallel workers sit idle | Guard both |
| C14 | `emis_to_dt(emi_vars = c(...))` gives a misleading error | `assert_string` |
| C15 | `continue` cannot resume; `output_path = NULL` probes `//file` | Require `output_path` |
| C16 | `ef_local` as a data.frame is documented but rejected | Fix the doc, or accept it |
| C17 | The returned `$tech` is the user input, not the tech actually used | Return the effective tech |
| C18 | EMEP rounds speed before the equation, which is undocumented | Document it |
| C19 | A non-integer `model_year` gives a cryptic error | `assert_integerish` |
| D7 | `setup.R` uses `parallel = TRUE` | `FALSE` (see #26) |
| D8 | `actions/checkout@v2`; duplicate R-CMD-check workflow name; old RSPM URL; the cran-comments CI matrix is wrong | Update |
| DOC-16 | CITATION `author` is a single string, so it renders as "Bazzo JP"; pages are missing | Use `c(person(...))` |
| DOC-22…37 | Stale README output; non-existent `ef_emep_europe`/`emep_europe`; literal "@param" text in the Rd; `spatial_resolution` says "minimum" where it should say "maximum"; `tech="-"` is undocumented; `ef_brazil_cetesb` @return; typos and checkRd notes; `\donttest` examples use unguarded `progressr`/`parallel`; NEWS is boilerplate and mentions `emi_summary`; the preprint is cited instead of TRD 2023; small vignette slips | Text edits |
| F1 | Empty tracked `R/_pkgdown.yml` (R CMD build flags it as an invalid file name) | `git rm` |
| F2 | `lwgeom` is unused in R/ and the vignettes. `progressr` is used in the intro vignette, so keep it | Drop `lwgeom` |

## Suggested order of work

1. **#3, #4, #6, #7, #5:** small local fixes, each with a known-value test.
2. **#1 + #2 together** (the slope workflow), with a 2-shape, mixed-slope test.
3. **#26–#29:** run the tests in R CMD check, fix the vacuous tests, and add value assertions.
4. **#8–#24** (input validation and silent-default traps), then #25.
5. **#30–#31 before any CRAN submission**, then the MINOR batch.

## Dropped after verification

- **D2 as a standalone CRITICAL:** both "failing" tests pass with CRAN gtfs2gps 2.1-4 and fail only with dev 2.1.4.9000. The root cause is kept as #8.
- **F2 "drop progressr":** it is used in the intro vignette.
- **"No heightfile test":** a slope test exists, but it is trivial (folded into #29).

## Verdict changes versus the draft

- **Upgraded:** B6 → CRITICAL (#5).
- **Downgraded:**
  - A6 and A7 → MAJOR: these are docs/silent-default traps.
  - A9 → MINOR.
  - C2 → MINOR.
  - D1 → MAJOR: covr runs the tests.
  - D2 merged into #8.
- **Scope corrected:**
  - A4: tyre wear only.
  - B4: FC only; A10 merged into it.
  - A14: also reproduces with CRAN gtfs2gps.
  - E1: only the pkgdown host returns 404.
- **Merged:** B1, B2, B3, B5 and B10 → #1; D5 and D6 → #29.
- **Corrected evidence:** A2 (actual numbers); A3 (18–20×, and the wrong carbon ratio).
- **New:** #15.
