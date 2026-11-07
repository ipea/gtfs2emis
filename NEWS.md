# gtfs2emis (development version)

- Errors and messages now use {cli}. All errors have class `gtfs2emis_error`, and a missing emission-factor combination has class `gtfs2emis_missing_ef`, so they can be caught with `tryCatch()`. Input checks still use {checkmate}. Error and message wording changed, so code that matches the old text with a regular expression may need updating. New dependencies: cli, rlang.
- `emis_summary()` no longer calls a {testthat} function at run time, so it works without {testthat} installed.
- The vignettes were rewritten for clarity, with consistently formatted code. They now state what `emission_model()` does with a detailed fleet table: it does not read `shape_id`, so route-specific fleets need one `emission_model()` call per group of shapes.
- Links now point to the new GitHub organisation and website (`github.com/ipea/gtfs2emis`, <https://ipea.github.io/gtfs2emis/>), replacing the old `ipeaGIT` addresses.
- `emi_europe_emep_wear()` documentation listed `"Coaches Std >18 t"` as a `veh_type`; the accepted value is `"Coaches Std <=18 t"`.
- `transport_model()` was rewritten for the new {gtfs2gps} interface. It runs `gtfs2gps::gtfs2gps()` once on the whole feed, in memory, after limiting speeds with `gtfstools::set_min_speed()` and `gtfstools::set_max_speed()`. Results change:
  - It requires the development version of {gtfs2gps} (>= 2.1-4.9000, installed from GitHub through `Remotes: ipea/gtfs2gps`): with gtfs2gps 2.1-4, some trips lost segments or got segments joining two trips (608 segments instead of 632 on the Detroit example feed), and an empty feed crashed R. Until that version of {gtfs2gps} is on CRAN, this version of gtfs2emis can't be released there.
  - Blank stop times are filled with `gtfstools::interpolate_stop_times()` before the speed limits are applied; the feed's own times are kept.
  - Trips now end at their last timed stop. They also start at their first timed stop, so the parts of a shape before the first stop and after the last stop of a trip are no longer returned, and distances and emissions are lower (about 19% less distance on the Curitiba example feed).
  - Trips on shapes shared by several routes are no longer dropped. All the trips of shapes shared by several routes or stop patterns are now converted, so emissions on those shapes are higher.
  - Distances are spherical and rounded, so slightly shorter.
  - Segment speeds still outside `min_speed`–`max_speed` are set to the nearest limit. Missing speeds are replaced by `new_speed`, which must now be between `min_speed` and `max_speed`, or, when `new_speed = NULL`, by the average speed (total distance / total time) of the trips of the same `shape_id`, or of the whole feed if the shape has none. Before, out-of-range speeds were also replaced, with the distance-weighted mean speed of each shape. When a speed changes, the segment's duration and the later times of the trip (`from_timestamp`, `to_timestamp`, `timestamp`, `cumtime`) are shifted accordingly; each trip keeps its first departure.
  - A feed with nothing to convert (for example, empty after filtering) gives a `gtfs2emis_error`.
  - `parallel` and `continue` are deprecated: they are ignored and give a warning (class `gtfs2emis_deprecated`). Set the number of threads with `ncores`, which now defaults to `2` and accepts `Inf`.
  - With `output_path`, one `.rds` file is saved per `shape_id`, as before, but the whole feed is processed in memory. A `%` in a `shape_id` is now always encoded (as `%25`), so ids round-trip with `utils::URLdecode()`; ids containing a `%XX` sequence (e.g. `"x%20y"`) get new file names.
  - A GTFS path is read with `gtfstools::read_gtfs()`, and {gtfstools} (>= 2.0.1) moves from Suggests to Imports.

## Performance

Compared with gtfs2emis 0.1.2 (CRAN), single-threaded, on the example feeds:

- `transport_model()` is 18–33 times faster and allocates 12–14 times less memory (Dublin: 57 s and 3.2 GB down to 1.7 s and 0.24 GB).
- `ef_europe_emep()` computes each emission factor once per distinct speed, slope and load, instead of once per road segment: 6 times faster and 8 times less memory with 10^6 speeds. `emission_model(ef_model = "ef_europe_emep")` allocates 25–35% less memory than in 0.1.2 on the Dublin feed. Results are identical.
- `emis_grid()` is 7–52 times faster and allocates 3.5–22 times less memory on the example feeds (Dublin, 459-cell grid: 17 s and 323 MB down to 0.9 s and 33 MB per day; 43 s and 884 MB down to 0.8 s and 41 MB per hour). It no longer builds a dense grid-by-segment matrix, which could need several GB on large grids; it intersects each road segment with the grid once instead of once per time bin; and it cuts longitude/latitude data with planar instead of spherical geometry (see below).
- `emis_to_dt()` builds its long table in one pass, and `emission_model()` multiplies emission factors by distances without intermediate copies: on 160,000 Dublin segments, `emis_to_dt()` is 1.65 times faster and allocates 37% less memory, `emis_summary()` 1.2–1.45 times faster and 17% less, and `emission_model()` 1.25 times faster with 26% less memory for EMEP (52% less for CETESB). `ef_usa_moves()` and `ef_usa_emfac()` find the speed bin in one pass: 1.2 times faster and 23% less memory with 10^6 speeds. Results are identical.
- `emis_to_dt()` now gives a {cli} error when the emission columns have different lengths or a `segment_vars` column has the wrong length.

## Bug fixes

- `ef_europe_emep()`, `ef_scaled_euro()`, `emi_europe_emep_wear()` and `emission_model()` failed with an unclear base R error (e.g. "argument is of length zero") instead of their {cli} error when `speed`, `dist` or an emission factor had the wrong units, such as `m` instead of `km/h`.
- `transport_model()`: `min_speed`, `max_speed` or `new_speed` given as a {units} object that isn't a speed (e.g. `m`) now raises a {cli} error instead of a {units} error.

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
- `emission_model(ef_model = "ef_brazil_scaled_euro")` ignored the `tech` column of `fleet_data` and always used `"SCR"`. Results change for Euro IV and later rows whose `tech` is not `"SCR"` (e.g. `"EGR"`). `tech` must now be a valid EMEP/EEA technology for each Euro class (e.g. `"-"` for Euro III, `"SCR"` or `"EGR"` for Euro IV and V, `"DPF+SCR"` for Euro VI).
- `emission_model()` now checks `process` for every `ef_model`. Wear processes with a model other than `ef_europe_emep` gave an unclear error, and `process = c("hot_exhaust", "tyre")` silently returned hot exhaust only; both are now errors, as is an unknown process.
- `emission_model()` now errors when `output_path` is the `tp_model` folder, which used to overwrite the transport model files.
- `transport_model()` now respects the `ncores` argument. Previously, it always used all available cores minus one when `parallel = TRUE`.
- `emission_model(quiet = TRUE)` now also suppresses messages when `tp_model` is an `sf` object.
- `emission_model()` now checks upfront that `fleet_data` has a `veh_type` column for `ef_europe_emep`, and a `fuel` column for `ef_usa_moves` and `ef_usa_emfac`, instead of failing later with an unclear error.
- `emi_europe_emep_wear()`:
  - `speed` and `load` must have length 1 or the length of `dist`. Other lengths were silently recycled and now give an error.
  - Brake wear with one `load` per segment returned a segment-by-segment block of columns per vehicle; it now returns one value per segment.
  - `pollutant = "PM1.0"` failed with an unclear error ("Can't assign 2 names to a 0-column data.table") for tyre and brake wear; it now uses the EMEP/EEA PM1.0 mass fractions (0.060 of TSP for tyre wear, 0.100 for brake wear).
- `ef_brazil_cetesb()` returned `NA` emission factors, without error, for RCHO, ETOH and FS, which have no values for buses in `ef_brazil_cetesb_db`. A missing emission factor is now an error of class `gtfs2emis_missing_ef`, and `model_year` must be a whole number.
- `emis_grid()` failed when the emission columns had no units; they are now kept as numbers.
- `emis_grid()` lost part of the emissions of a road segment that doubles back on itself (for example, a route turning around at a terminal) when the grid had a projected coordinate reference system: the overlapping parts were merged before the segment was split between cells (0.1% of the emissions on the Dublin example feed).
- `emis_grid()` now splits road segments between the cells of a longitude/latitude grid with planar geometry, the straight cell edges drawn by `sf::st_make_grid()`, instead of spherical geometry; segment lengths are still geodesic. Results change slightly: on longitude/latitude grids of the example feeds, emissions per cell change by at most 0.02%, grid totals still equal the segment totals, and a 459-cell Dublin grid gains one cell with zero emissions (touched by a segment at a single point). Grids and segments that cross the antimeridian (±180°) are not supported.
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
transit buses from EMEP model (detailed in [vignette non-exhaust](https://ipea.github.io/gtfs2emis/articles/gtfs2emis_non_exhaust_ef.html))
- Adjust the functions `emis_summary()`, `emis_grid()`, `emission_model()` to incorporate non-exhaust emissions estimates

# gtfs2emis 0.1.0

- Initial CRAN release.