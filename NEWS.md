# gtfs2emis (development version)

- Errors and messages now use {cli}. All errors have class `gtfs2emis_error`, and a missing emission-factor combination has class `gtfs2emis_missing_ef`, so they can be caught with `tryCatch()`. Input checks still use {checkmate}. Error and message wording changed, so code that matches the old text with a regular expression may need updating. New dependencies: cli, rlang.
- `emis_summary()` no longer calls a {testthat} function at run time, so it works without {testthat} installed.

# gtfs2emis 0.1.2

- Minor improvements and internal fixes to emission estimation workflows.
- Small documentation updates and performance adjustments.

# gtfs2emis 0.1.1

- New function `emi_europe_emep_wear()`, to estimate non-exhaust sources of 
transit buses from EMEP model (detailed in [vignette non-exhaust](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_non_exhaust_ef.html))
- Adjust the functions `emi_summary()`, `emis_grid()`, `emission_model` to incorporate non-exhaust emissions estimates

# gtfs2emis 0.1.0

- Initial CRAN release.