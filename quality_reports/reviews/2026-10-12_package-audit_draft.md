# gtfs2emis 0.1.2 — package audit (DRAFT, pre-adversarial review)

**Date:** 2026-10-12 · **Scope:** R/, data/, data-raw/, tests/, vignettes, README, DESCRIPTION, CI
**Method:** four independent read-only auditors: core pipeline (PIPE), emission factors (EF), documentation (DOC), package/tests/CRAN (PKG). Most findings were reproduced in R 4.5.1 with `load_all()`, gtfs2gps 2.1.4.9000 (dev), gtfstools 1.4.0. `R CMD check --as-cran --no-manual` was run on a `git archive` copy and gave 0 E / 1 W / 0 N; the W is the incoming-feasibility URL and version warning. Tests were run separately and gave 2 failures.
**Source tags:** the original auditor IDs are kept in brackets so evidence can be traced. Repro scripts are in the session scratchpad (`audit_pipeline/`, `audit_ef/`, `audit_docs/`, `audit_pkg/`).

Severity: **CRITICAL** = wrong numbers or a crash in a documented workflow. **MAJOR** = wrong numbers in edge cases, silent bad input, misleading docs, or a broken test gate. **MINOR** = robustness, clarity, hygiene.

---

## A. Silent wrong results (highest priority)

### A1. Slopes > +7% classed as steep *downhill* (-0.06) — CRITICAL [PIPE-01, DOC-18]
- **Where:** `R/slope_class_europe_emep.R` (`fcase`, `slope > +0.070, -0.06`) and the roxygen table.
- **Why:** the steepest uphill links, where emissions are highest, get the lowest-emission EF.
- **Fix:** `slope > 0.070, 0.06` in the code and the doc. Also add the missing `|---|---|` header row so the Rd table renders.

### A2. MOVES filters on the wrong column, so mixed-fuel fleets get wrong EFs — CRITICAL [EF-04]
- **Where:** `R/ef_usa_moves.R:258-260`, `fuel %in% tmp_fuel[j]`. The DB column is `fuel_type`, so `fuel` resolves to the function argument and is recycled.
- **Evidence:** `fuel=c("D","CNG")` gives D CO = 20.38 / 9.64 g/km, against 2.70 / 0.875 for `fuel="D"` alone.
- **Fix:** `fuel_type %in% tmp_fuel[j]`, plus a test with a mixed-fuel fleet.

### A3. CNG FC/CO2 come from an energy factor (MJ/km), about 17× too low — CRITICAL [EF-05]
- **Where:** `data-raw/ef_europe_emep_db.R:221,252-253` → `data/ef_europe_emep_db.rda`.
- **Evidence:** CNG EEV at 19 km/h gives FC = EC = 20.45 and CO2 = 64.85 "g/km". Diesel Euro IV gives 1116 g/km CO2.
- **Fix:** convert MJ to kg fuel with the CNG LHV before applying CO2/fuel, or drop CNG FC/CO2. Label EC as MJ/km. Rebuild the .rda.

### A4. Tyre/brake wear: axle count matched by set membership, not by row — CRITICAL [EF-06, PIPE-14]
- **Where:** `R/emi_europe_emep_wear.R:281`, `n_axle_table[veh %in% tmp_veh_type, n_axle]`.
- **Evidence:** Artic+Midi and Midi+Artic give identical results, and the 3-axle Artic gets 2 axles. A repeated veh_type causes recycling and wrong values.
- **Fix:** `n_axle_table$n_axle[match(tmp_veh_type, n_axle_table$veh)]`.

### A5. `fleet_composition` never checked to sum to 1 — MAJOR [PIPE-08]
- **Where:** `R/emission_model.R:197-269`; the docs say the shares sum to 1.
- **Evidence:** `c(1,1,1)` gives exactly 3× the emissions with no warning.
- **Fix:** assert values in [0,1] and stop when `abs(sum - 1) > 1e-6`.

### A6. `reference_year` documented as a `fleet_data` column but ignored — CRITICAL [PIPE-10, DOC-02]
- **Where:** `R/emission_model.R:58-59` (docs) vs 359/367. The examples and the fleet vignette (`calendar_year`) put it in fleet data.
- **Evidence:** MOVES with fleet `reference_year` 2015 vs 2020 gives identical output; the default argument value 2020 is used silently.
- **Fix:** either read the column when present, or remove it from the docs, examples and vignette and pass the argument instead.

### A7. "Detailed" fleet table with `shape_id` promised, but never used — CRITICAL [DOC-01]
- **Where:** `README.md:100-105`, intro vignette 146-147, fleet vignette 27-28/43.
- **Evidence:** `shape_id` values matching no route still produce emissions spread uniformly.
- **Fix:** remove the claim, or say that users must split `tp_model` by shape. Alternatively, implement the allocation.

### A8. `ef_brazil_scaled_euro` requires `tech` but ignores it (always "SCR") — MAJOR [PIPE-07, DOC-13]
- **Where:** `R/emission_model.R:382-392`.
- **Fix:** pass `tech = fleet_data$tech` to `ef_scaled_euro()`.

### A9. Brake speed correction applied above 90 instead of 95 km/h — MAJOR [EF-07, DOC-07]
- **Where:** `R/emi_europe_emep_wear.R:259`. This overwrites the documented linear 90–95 segment.
- **Fix:** `speed > units::set_units(95, "km/h")`.

### A10. Euro IV FC/CO2 forced to `tech = "-"` even though SCR/EGR rows exist — MAJOR [EF-12]
- **Where:** `R/ef_europe_emep.R:202-209`.
- **Fix:** fall back only when `nrow(match) == 0`.

### A11. Silent length truncation/recycling of fleet vectors — MAJOR [EF-10, EF-11, DOC-14, PIPE-20]
- **Where:**
  - `ef_europe_emep()` truncates `veh_type`/`tech`/`fuel`/`fcorr` to `length(euro)`. Its own example drops a vehicle.
  - `ef_scaled_euro()` recycles a short `ef_local` (`R/ef_scaled_euro.R:319`).
  - `multiply_ef()` doesn't check `ncol(EF)` against the fleet.
- **Fix:** recycle length-1 inputs only and `stop()` on any other mismatch. Fix the example.

### A12. EF lookups accept non-mass "pollutants" and label them g/km — MAJOR [EF-13, EF-14, DOC-17]
- **Where:**
  - CETESB: `KML` (km/L, wrongly described as "VKT"), `gD/KWH`, `gCO2/KWH`, `FS`. `RCHO`/`ETOH`/`FS` are all-NA.
  - EMEP: `SPN23 [#/kWh]`.
- **Fix:** restrict the choices to g/km pollutants, or give each its own units. Error on all-NA pollutants.

### A13. Speed units ignored in MOVES/EMFAC — MAJOR [EF-09]
- **Where:** `ef_usa_emfac.R:72-83`, `ef_usa_moves.R:231-241` (`as.numeric(speed)`).
- **Evidence:** 10 m/s gives the same result as 10 km/h.
- **Fix:** `units::set_units(speed, "km/h")` before stripping the units.

### A14. NA timestamps from `transport_model()` pass through silently — MAJOR [PIPE-15, PKG-01]
- **Where:** NA timestamps come from upstream `gtfs2gps::adjust_speed` on the current gtfs2gps dev version.
- **Evidence:** `emis_summary(by="time")` creates an `NA` hour holding about 7% of NOx. `emis_grid(.., "hour")` stops. This also causes the 2 failing tests.
- **Fix:** confirm against the CRAN gtfs2gps release. Warn in `transport_model()` when the output has NA timestamps, and report upstream.

### A15. Stale temp files from an aborted run leak into later output — MAJOR [PIPE-06, PKG-12]
- **Where:** `R/transport_model.R`. It uses the fixed `tempdir()/gps/` and `gps_adjust/`, and cleanup is registered only at the end.
- **Fix:** create a per-call `tempfile("gps")` folder with `on.exit(unlink(dir, recursive = TRUE))` right after it is created.

## B. Crashes in documented workflows

### B1. `heightfile` + `ef_europe_emep` crashes on any route with repeated slope classes — CRITICAL [EF-02, PIPE-03]
- **Where:** `R/ef_europe_emep.R:230-305`; it errors with "NAs are not allowed in subscripted assignments".
- **Why the example passes:** all of its slopes are 0.
- **Fix:** evaluate once per `unique(slope, load)` and map each result back by index. Add a test with mixed, repeated slopes.

### B2. `slope_class_europe_emep()` fails with more than one shape — CRITICAL [PIPE-02]
- **Where:** `R/slope_class_europe_emep.R:400-408`. The endpoints are grouped `by = stop_sequence` only, which gives a height vector of the wrong length. With some shape lengths it would recycle silently instead.
- **Fix:** take the start and end vertex per LINESTRING row (`sf::st_startpoint`/`st_endpoint`).

### B3. `slope_class_europe_emep()` drops `timestamp` and other columns — MAJOR [PIPE-04, DOC-27]
- **Effect:** after `heightfile`, both `emis_summary(by="time")` and time-resolved `emis_grid()` fail.
- **Fix:** add the slope columns by reference instead of rebuilding the table.

### B4. Diesel FC for Euro I/II/III/V crashes because of duplicate DB rows — CRITICAL [EF-01, EF-25]
- **Where:** `ef_europe_emep_db` has 525 duplicated keys, mixing 2007/2013/2016 editions. `switch()` then gets length > 1.
- **Evidence:** Euro V + SCR is the default tech.
- **Also:** `data-raw/ef_europe_emep_db.R` can't rebuild the shipped .rda: it has a top-level `break()`, and the dedup keeps 0 copies of exact duplicates.
- **Fix:** dedup in data-raw with one edition per key and rebuild. Add a test that the key is unique.

### B5. `ef_scaled_euro()` with any slope vector longer than 1 errors — CRITICAL [EF-03]
- **Effect:** `ef_brazil_scaled_euro` + `heightfile` always fails.
- **Fix:** compute the SDC factor with `speed = rep(SDC, length(slope))`, or at slope 0 (document which).

### B6. `emis_grid()` crashes when two vehicles share a Euro stage — MAJOR [PIPE-11, EF-18]
- **Where:** EF/emi column names (`NOx_Euro_V`, `CO_2015`) are not unique per vehicle; `setnames` then fails.
- **Fix:** add the vehicle index to the column names and rename by position in `emis_grid()`.

### B7. `PM1.0` wear pollutant passes validation, then crashes — MAJOR [EF-08, DOC-05]
- **Fix:** rename the internal table entry `"PM1"` → `"PM1.0"`.

### B8. Valid `reference_year`/`model_year` ranges don't match the data — MAJOR [EF-16, DOC-04, DOC-30]
- **Mismatches:**
  - MOVES accepts 2010–2020, but the data covers 2015–2022. 2012 passes and then errors; 2021–22 are rejected.
  - EMFAC has no 2018.
  - The MOVES error message names `ef_usa_emfac_db`.
  - The shared roxygen template says 2015–2022.
- **Fix:** validate against `unique(db$reference_year)`, fix the message, and give each function its own template.

### B9. `process` mixing and wear for non-EMEP models are unhandled — MAJOR [PIPE-09]
- **Evidence:** `process = c("hot_exhaust","tyre")` silently returns exhaust only. CETESB + `"tyre"` fails with "object 'temp_emis' not found".
- **Fix:** `assert_subset(process, ...)`. Reject mixing, or combine the branches. Reject wear for non-EMEP models with a clear message.

### B10. `heightfile` rejects `terra::SpatRaster`; only `raster::RasterLayer` (not a dependency) or a path works — MAJOR [DOC-08]
- **Fix:** accept `SpatRaster` and document "file path or `terra::SpatRaster`".

## C. Validation and robustness

| ID | Issue | Fix | Sev |
|---|---|---|---|
| C1 [PIPE-05, PKG-07] | `transport_model()`: `upper = ncores <- availableCores(omit=1)` overwrites the user's `ncores` (it always uses every core but one) | `upper = parallelly::availableCores(omit = 1)` | MAJOR |
| C2 [PKG-08] | `gtfstools::read_gtfs()` is called unguarded in `transport_model()`, but gtfstools is in Suggests | Move gtfstools to Imports | MAJOR |
| C3 [EF-15] | `utils::data(...)` in the EF functions loads the DBs into `.GlobalEnv`, which overwrites and shadows user objects | Reference the lazy data `gtfs2emis::ef_*_db` directly | MAJOR |
| C4 [EF-17] | `checkmate::check_true()` (not `assert_`) in wear, so length checks never fire. Brake with a vector `load` returns an n×n matrix | `assert_true`; `outer()` for brake | MAJOR |
| C5 [PIPE-13] | `emis_grid()`: dense `st_intersects(sparse = FALSE)` runs out of memory at city scale | `lengths(sf::st_intersects(grid, net)) > 0` | MAJOR |
| C6 [PIPE-12] | `emis_summary(by = "time")` silently drops `segment_vars` | Keep them and add `timestamp_hour` | MINOR |
| C7 [EF-23] | `slope`/`load` not validated against the classes, so a misleading error results | `assert_subset()` | MINOR |
| C8 [PIPE-16] | `min/max_speed` validated as raw numbers (units ignored); undocumented floors of 2/3 | Convert to km/h first; document | MINOR |
| C9 [PIPE-17] | Slope assumes `dist` is in km (`1000 * dist`) | `units::set_units(dist, "m")` | MINOR |
| C10 [PIPE-18] | `emis_grid()` overwrites and then drops the user's grid `id` column | Use a private column name | MINOR |
| C11 [PIPE-19] | `emis_grid()` timestamp check is OR-ed, so a character `timestamp` passes | Require column AND class | MINOR |
| C12 [PIPE-20] | `multiply_ef()` `%like% "HC_"` is unanchored, so `HC_total` also adds NMHC | `paste0("^", i, "_")` | MINOR |
| C13 [PIPE-21] | With an sf `tp_model`: `quiet` is ignored, and `parallel` starts idle workers | Wrap messages; set up the plan only for path input | MINOR |
| C14 [PIPE-22] | `emis_to_dt(emi_vars = c(...))` does recursive `[[`, so the error is misleading | `assert_string` or loop | MINOR |
| C15 [PIPE-23] | `continue` can't resume (temp files are wiped); with `output_path = NULL` it probes `//file` (UNC on Windows) | Require `output_path`; skip the check when NULL | MINOR |
| C16 [EF-20, DOC-12] | `ef_scaled_euro(ef_local = data.frame)` is documented but rejected | Document a units matrix / the CETESB list (or accept data.frame) | MINOR |
| C17 [EF-19] | Returned `$tech` reports the user input, not the tech actually used after fallback | Return the effective tech | MINOR |
| C18 [EF-21] | EMEP rounds speed to an integer before the equation (undocumented) | Document, or don't round | MINOR |
| C19 [EF-22] | Non-integer `model_year` gives an empty or cryptic error | `assert_integerish` | MINOR |

## D. Tests and CI (the test gate is effectively off)

| ID | Issue | Fix | Sev |
|---|---|---|---|
| D1 [PKG-02] | `.Rbuildignore` has `^tests$`, so tests never run on CRAN or in R-CMD-check CI | Remove it; ignore `tests/test_joao`, `tests/tests_rafa`; `skip_on_cran()` the slow tests | CRITICAL |
| D2 [PKG-01] | 2 failing tests (`test_emis_grid.R:16`, `test_emis_summary.R:25`), caused by A14 | Resolve A14, then re-derive the expectations | CRITICAL |
| D3 [PKG-03] | `test_emission_model.R`: `default_tester()` defaults to the undefined `tp_model_bra`, so all 17 `expect_error`s pass for the wrong reason | Valid defaults plus `expect_error(regexp =)` | MAJOR |
| D4 [PKG-04] | `test_multiply_ef.R` uses the undefined `total_fleet`; `test_ef_usa_moves.R` passes `fleet_data_usa$year` (NULL) | Fix the objects; add `regexp=` | MAJOR |
| D5 [PKG-06] | Almost all value assertions are commented out; only dims/names/units are checked | Re-enable known-value checks with `tolerance =` | MAJOR |
| D6 [PKG-05] | No `test_transport_model.R`. `emission_model()` is only run for real with EMEP. No `heightfile` test (it would have caught B1–B3) | Add the tests; one successful run per `ef_model` | MAJOR |
| D7 [PKG-12] | `setup.R` runs `transport_model(parallel = TRUE)` with every core | `parallel = FALSE` | MINOR |
| D8 [PKG-11] | Workflows use `actions/checkout@v2`, a duplicate R-CMD-check workflow and an old RSPM URL; `cran-comments.md` misstates the CI matrix | Update | MINOR |

## E. Documentation

### E1. Every pkgdown link is dead (404): `ipeagit.github.io/gtfs2emis` — MAJOR [DOC-03, PKG-09]
- **Where:** DESCRIPTION URL, `_pkgdown.yml`, README, roxygen, NEWS, vignettes.
- **Why:** the repo moved to the `ipea` org. CRAN will flag this at the next submission.
- **Fix:** use `ipea.github.io/gtfs2emis` and `github.com/ipea/gtfs2emis`, including `BugReports`.

### E2. Other MAJOR doc errors
- **Missing or wrong in `emission_model()`/`transport_model()` docs:**
  - `emission_model()` @details omits the required `model_year` column [DOC-09].
  - The `transport_model()` return is documented as "data.table sf_linestring"; it is `sf`/`data.frame` [DOC-21].
  - `new_speed = NULL` is documented as "feed average"; it is actually each shape's average [DOC-20].
- **Wrong values or sources in the vignettes and README:**
  - The fleet vignette swaps the MOVES and EMFAC sources [DOC-10].
  - README and vignette list CETESB inputs as "Age, Fuel, EURO"; they are actually veh_type + model_year [DOC-11].
  - The EF vignette calls `data(ef_usa_moves)` etc.; those datasets don't exist (`*_db`) [DOC-15].
  - The wear docs list `"Coaches Std >18 t"`; the valid value is `<=18 t` [DOC-06].
- **`R/data.R` doesn't match the data** [DOC-19, EF-24]:
  - The EMEP DB has 9913 rows (not 6431) and undocumented columns.
  - The EMFAC and CETESB column lists are wrong.
  - Fix: regenerate `@format` from `str()`.
- **CITATION** renders the first author as "Bazzo JP"; it should be "Vieira, João Pedro Bazzo". Pages are missing [DOC-16].

### E3. MINOR doc fixes (batch)
- **Text and wording:**
  - README `names(emi_list)` output is stale, and the prose mentions `age`/`gps` [DOC-22].
  - Non-existent names `ef_emep_europe`/`emep_europe`, and literal "@param/@examples" text in rendered Rd [DOC-23].
  - `spatial_resolution` says "minimum"; it should say "maximum" [DOC-24].
  - `tech = "-"` is undocumented [DOC-25].
  - `ef_brazil_cetesb` @return is wrong [DOC-37].
  - Typos and checkRd NOTEs [DOC-35].
- **Examples:** `\donttest` examples use unguarded `progressr` and `parallel = TRUE`; one has a wrong comment [DOC-26].
- **NEWS and references:**
  - NEWS 0.1.2 is boilerplate, and 0.1.1 names `emi_summary()` [DOC-28].
  - DESCRIPTION and README cite the 2022 preprint instead of TRD 2023 (doi:10.1016/j.trd.2023.103757) [DOC-29].
- **Vignettes:** slips in the intro, EF, fleet and non-exhaust vignettes [DOC-31…34].

## F. Hygiene

- **F1** [DOC-36, PKG-10]: stray empty tracked `R/_pkgdown.yml`, which `R CMD build` reports as an invalid file name. Fix: `git rm`.
- **F2** [PKG-08]: Suggests `lwgeom` and `progressr` appear unused in `R/`. Check the vignettes before dropping them.

---

## Suggested order of work

1. **A1–A4, B4** (wrong numbers and crashes in core EF paths): small, local code fixes, each with a known-value test.
2. **D1–D4** (turn the test gate back on), so later fixes are protected.
3. **B1–B3, B5** (the `heightfile`/slope workflow) as one plan.
4. **A5–A15, B6–B10, C1–C5.**
5. **E1** before any CRAN submission. Then the remaining docs (E2, E3), C6–C19 and F.

**Count (deduplicated):** 63 issues. A: 15 · B: 10 · C: 19 · D: 8 · E: 3 groups (≈30 doc items) · F: 2.
