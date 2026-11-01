# gtfs2emis (development version)

- Errors and messages now use {cli}. All errors have class `gtfs2emis_error`, and a missing emission-factor combination has class `gtfs2emis_missing_ef`, so they can be caught with `tryCatch()`. Input checks still use {checkmate}. Error and message wording changed, so code that matches the old text with a regular expression may need updating. New dependencies: cli, rlang.
- `emis_summary()` no longer calls a {testthat} function at run time, so it works without {testthat} installed.

## Bug fixes

- `transport_model()` no longer merges shapes left over in `tempdir()` by a previous interrupted or failed run into its output. Intermediate files from earlier runs are now removed unless `continue = TRUE`.
- `transport_model()` now respects the `ncores` argument. Previously, it always used all available cores minus one when `parallel = TRUE`.
- `emission_model(quiet = TRUE)` now also suppresses messages when `tp_model` is an `sf` object.
- `emission_model()` now checks upfront that `fleet_data` has a `veh_type` column for `ef_europe_emep`, and a `fuel` column for `ef_usa_moves` and `ef_usa_emfac`, instead of failing later with an unclear error.

## Documentation

- `emission_model()`: corrected function names (`ef_europe_emep`), the description of `quiet` and of the return value, and the list of required `fleet_data` columns. Clarified that the reference year of `ef_usa_moves` and `ef_usa_emfac` is set by the `reference_year` argument, not by a `fleet_data` column. Added an `ef_brazil_scaled_euro` example and removed the unused `progressr::with_progress()` wrappers from the examples.

# gtfs2emis 0.1.2

- Minor improvements and internal fixes to emission estimation workflows.
- Small documentation updates and performance adjustments.

# gtfs2emis 0.1.1

- New function `emi_europe_emep_wear()`, to estimate non-exhaust sources of 
transit buses from EMEP model (detailed in [vignette non-exhaust](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_non_exhaust_ef.html))
- Adjust the functions `emi_summary()`, `emis_grid()`, `emission_model` to incorporate non-exhaust emissions estimates

# gtfs2emis 0.1.0

- Initial CRAN release.