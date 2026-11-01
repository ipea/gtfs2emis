# Changelog

## gtfs2emis (development version)

- Errors and messages now use {cli}. All errors have class
  `gtfs2emis_error`, and a missing emission-factor combination has class
  `gtfs2emis_missing_ef`, so they can be caught with
  [`tryCatch()`](https://rdrr.io/r/base/conditions.html). Input checks
  still use {checkmate}. Error and message wording changed, so code that
  matches the old text with a regular expression may need updating. New
  dependencies: cli, rlang.
- [`emis_summary()`](https://ipeagit.github.io/gtfs2emis/reference/emis_summary.md)
  no longer calls a {testthat} function at run time, so it works without
  {testthat} installed.

## gtfs2emis 0.1.2

CRAN release: 2026-02-12

- Minor improvements and internal fixes to emission estimation
  workflows.
- Small documentation updates and performance adjustments.

## gtfs2emis 0.1.1

CRAN release: 2024-12-02

- New function
  [`emi_europe_emep_wear()`](https://ipeagit.github.io/gtfs2emis/reference/emi_europe_emep_wear.md),
  to estimate non-exhaust sources of transit buses from EMEP model
  (detailed in [vignette
  non-exhaust](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_non_exhaust_ef.html))
- Adjust the functions `emi_summary()`,
  [`emis_grid()`](https://ipeagit.github.io/gtfs2emis/reference/emis_grid.md),
  `emission_model` to incorporate non-exhaust emissions estimates

## gtfs2emis 0.1.0

CRAN release: 2022-11-14

- Initial CRAN release.
