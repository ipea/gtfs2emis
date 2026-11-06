# gtfs2emis (development version)

- Errors and messages now use {cli}. All errors have class `gtfs2emis_error`, and a missing emission-factor combination has class `gtfs2emis_missing_ef`, so they can be caught with `tryCatch()`. Input checks still use {checkmate}. Error and message wording changed, so code that matches the old text with a regular expression may need updating. New dependencies: cli, rlang.
- `emis_summary()` no longer calls a {testthat} function at run time, so it works without {testthat} installed.
- `transport_model()` was rewritten for the new {gtfs2gps} interface. It runs `gtfs2gps::gtfs2gps()` once on the whole feed, in memory, after limiting speeds with `gtfstools::set_min_speed()` and `gtfstools::set_max_speed()`. Results change:
  - It requires the development version of {gtfs2gps} (>= 2.1-4.9000, installed from GitHub through `Remotes: ipea/gtfs2gps`): with gtfs2gps 2.1-4, some trips lost segments or got segments joining two trips (608 segments instead of 632 on the Detroit example feed), and an empty feed crashed R. Until that version of {gtfs2gps} is on CRAN, this version of gtfs2emis can't be released there.
  - The parts of a shape before the first stop and after the last stop of a trip are no longer returned (about 19% less distance on the Curitiba example feed).
  - Segment speeds still outside `min_speed`–`max_speed` are set to the nearest limit; their timestamps are not changed. Missing speeds are replaced by `new_speed` or, when `new_speed = NULL`, by the distance-weighted mean speed of the whole feed (before, out-of-range speeds were also replaced, with the mean of each shape).
  - A feed with nothing to convert (for example, empty after filtering) gives a `gtfs2emis_error`.
  - `parallel` and `continue` are deprecated: they are ignored and give a warning (class `gtfs2emis_deprecated`). Set the number of threads with `ncores`, which now defaults to `2` and accepts `Inf`.
  - With `output_path`, one `.rds` file is saved per `shape_id`, as before, but the whole feed is processed in memory. A `%` in a `shape_id` is now always encoded (as `%25`), so ids round-trip with `utils::URLdecode()`; ids containing a `%XX` sequence (e.g. `"x%20y"`) get new file names.
  - A GTFS path is read with `gtfstools::read_gtfs()`, and {gtfstools} (>= 2.0.1) moves from Suggests to Imports.

## Bug fixes

- `ef_europe_emep()`: 1138 fuel consumption (FC) rows of `ef_europe_emep_db` held energy consumption in MJ/km labelled g/km, so FC for Conventional diesel, biodiesel and CNG buses was about 21–27 times too low. They are now converted to g/km with the EMEP/EEA guidebook net calorific values. FC no longer crashes for diesel Euro I, II, III and V (duplicated rows; the 2007/2013 rows are kept), and CNG CO2 was about 18 times too low. `ef_europe_emep_db` now has 9388 rows instead of 9913, and `"EC"` is documented as MJ/km. Results change (#110).

- Road slope (`emission_model(heightfile = )`) works again. Results change when a height file is used:
  - `ef_europe_emep()` no longer crashes when `slope` or `load` has several different values. Values outside the EMEP/EEA grid are now an error, and `slope` is rounded to two decimals. Pollutants that are tabulated only at slope 0 and load 0.5 (CH4, NH3, N2O, and some CNG and hybrid combinations) now use that value, with a message, instead of failing.
  - `slope_class_europe_emep()` classed slopes above 7% as -6% instead of +6%, and mixed segment endpoints across trips and shapes. It now reads the first and last point of each segment, projects them to the raster's coordinate reference system, keeps all input columns, and treats segments outside the raster as flat, with a warning. It returns a plain `sf` object (no longer also a `data.table`) and errors if `tp_model` has non-LINESTRING geometries or no coordinate reference system.
  - `ef_scaled_euro()` (and `emission_model(ef_model = "ef_brazil_scaled_euro", heightfile = )`) no longer crashes with a `slope` vector. The reference factor at `SDC` now always uses slope 0 and load 0.5, so results also change for a non-default scalar `slope` or `load`.

- `slope_class_europe_emep()` now errors when `tp_model` has no rows, and uses the units of `dist` when it has them (it assumed km).
- `ef_europe_emep()` argument checks:
  - `veh_type`, `euro`, `fuel`, `tech` and `fcorr` must each have length 1 or one common length. Before, lengths were matched against `euro` only, so extra vehicle types were silently dropped and a single `euro` returned only the first `veh_type`. Unequal lengths now give an error, and a length-1 `euro` is used for every `veh_type` (the output columns then share a name). `fcorr` must be non-negative.
  - CNG Euro EEV buses now work with the default `tech = "SCR"`; `"-"` is used, with a message, as for Euro I–III.
  - `"SPN23 [#/kWh]"` (a particle number per kWh, not a g/km factor) is no longer accepted as a pollutant.
  - `"EC"` (energy consumption) is now returned in MJ/km instead of being labelled g/km. It can no longer be converted to mass units and is rejected by `emission_model(ef_model = "ef_europe_emep")` and `ef_scaled_euro()`.

- `ef_usa_moves()` returned wrong emission factors, without warning, when `fuel` had more than one value (mixed-fuel fleets): the fuel filter used the `fuel` argument instead of the `fuel_type` column. Results change for mixed-fuel fleets (#111).
- `emi_europe_emep_wear()` underestimated bus brake wear by about 38%: it applied the heavy-duty factor of the EMEP/EEA 2019 guidebook (1.956, chapter 1.A.3.b.vi, equation 6) to the passenger-car brake-wear factor of earlier editions (0.0075 g/km) instead of the 2019 value (0.0122 g/km). Brake-wear emissions of all pollutants increase by about 63% (#113).
- `emi_europe_emep_wear()` assigned tyre axle counts in the order of its internal lookup table rather than the order of `veh_type`, so articulated and standard buses could swap axle counts. Tyre-wear results change when `veh_type` is not in table order or repeats a type (#112).
- `transport_model()` now respects the `ncores` argument. Previously, it always used all available cores minus one when `parallel = TRUE`.
- `emission_model(quiet = TRUE)` now also suppresses messages when `tp_model` is an `sf` object.
- `emission_model()` now checks upfront that `fleet_data` has a `veh_type` column for `ef_europe_emep`, and a `fuel` column for `ef_usa_moves` and `ef_usa_emfac`, instead of failing later with an unclear error.
- `emi_europe_emep_wear()`: the brake-wear speed correction now applies the constant 0.185 above 95 km/h, as documented and in the EMEP/EEA guidebook, instead of above 90 km/h. Brake-wear emissions between 90 and 95 km/h increase.
- `emission_model()` now only reads files ending in `.rds` from a `tp_model` folder, and parallel runs no longer warn about random-number seeds.
- `emis_grid(time_resolution = "minute")` labels are zero-padded (`"09:05"` instead of `"9:5"`), and time-resolved output of `emis_grid()` and `emis_summary(by = "time")` is now sorted by time.
- `emis_to_dt()` now requires `emi_vars` to be a single name, instead of failing with a misleading units error.

## Documentation

- `emission_model()`: corrected function names (`ef_europe_emep`), the description of `quiet` and of the return value, and the list of required `fleet_data` columns. Clarified that the reference year of `ef_usa_moves` and `ef_usa_emfac` is set by the `reference_year` argument, not by a `fleet_data` column. Added an `ef_brazil_scaled_euro` example and removed the unused `progressr::with_progress()` wrappers from the examples.
- `transport_model()`: corrected the `spatial_resolution` and `output_path` descriptions and the return class (`sf`).
- Vignettes: fixed the swapped MOVES/EMFAC sources and fleet column names, the dataset names in `data()` calls, typos and stale output descriptions; `data.table` functions are now called with `data.table::`, and the intro vignette runs with `parallel = FALSE`.
- README and citation: updated the `emission_model()` output, cite the 2023 TRD article, and fixed the author names in `inst/CITATION`.

# gtfs2emis 0.1.2

- Minor improvements and internal fixes to emission estimation workflows.
- Small documentation updates and performance adjustments.

# gtfs2emis 0.1.1

- New function `emi_europe_emep_wear()`, to estimate non-exhaust sources of 
transit buses from EMEP model (detailed in [vignette non-exhaust](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_non_exhaust_ef.html))
- Adjust the functions `emis_summary()`, `emis_grid()`, `emission_model()` to incorporate non-exhaust emissions estimates

# gtfs2emis 0.1.0

- Initial CRAN release.