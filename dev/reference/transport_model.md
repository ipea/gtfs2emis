# Transport model

This function converts a public transport data set in GTFS format into
road segments between consecutive stops of each trip, with their times,
distances and speeds, using the gtfs2gps package. The function also
allows users to set the spatial resolution of the output and to keep the
speed of public transport vehicles within a `min_speed` and `max_speed`
range.

## Usage

``` r
transport_model(
  gtfs_data,
  min_speed = 2,
  max_speed = 80,
  new_speed = NULL,
  parallel = NULL,
  ncores = 2,
  spatial_resolution = 100,
  output_path = NULL,
  continue = NULL
)
```

## Arguments

- gtfs_data:

  A path to a GTFS file or a GTFS data organized as a list of
  `data.tables` created with
  [`gtfstools::read_gtfs()`](https://ipea.github.io/gtfstools/reference/read_gtfs.html).

- min_speed:

  numeric (in km/h) or a speed units value. Minimum valid speed, at
  least 2 km/h. Defaults to `2` km/h. Stop times are first adjusted with
  [`gtfstools::set_min_speed()`](https://ipea.github.io/gtfstools/reference/set_min_speed.html),
  which can change the arrival and departure times of vehicles at
  transit stops. Segment speeds that are still below `min_speed` are
  then set to `min_speed`. The segment's duration becomes its distance
  divided by the new speed, and the later times of the trip are shifted
  by the difference (each trip keeps its first departure). Durations are
  rounded to whole seconds, so a very short segment (under about 11 m at
  80 km/h) can keep 0 s.

- max_speed:

  numeric (in km/h) or a speed units value. Maximum valid speed, at
  least 3 km/h. Defaults to `80` km/h. As for `min_speed`, stop times
  are first adjusted with
  [`gtfstools::set_max_speed()`](https://ipea.github.io/gtfstools/reference/set_max_speed.html),
  and segment speeds still above `max_speed` are set to `max_speed`,
  with the trip's times shifted in the same way.

- new_speed:

  numeric (in km/h) or a speed units value, between `min_speed` and
  `max_speed`. Speed used for segments without a speed; the trip's times
  are shifted as for `min_speed`. When `new_speed = NULL` (the default),
  the function uses the average speed (total distance / total time) of
  the trips of the same `shape_id`, after capping, or of the whole feed
  if the shape has none.

- parallel:

  **Deprecated.** This argument is ignored, and using it gives a
  warning. Use `ncores` instead.

- ncores:

  Number of threads used. Defaults to 2. If `Inf`, it uses all threads
  available, as given by
  [`data.table::getDTthreads()`](https://rdrr.io/pkg/data.table/man/openmp-utils.html).
  Values above that number are reduced to it.

- spatial_resolution:

  The spatial resolution in meters. Defaults to `100`. The function only
  creates points in order to guarantee that the maximum distance between
  two consecutive points will be at most the `spatial_resolution` value.
  If a given GTFS shape_id has two consecutive points with a distance
  smaller than the spatial resolution, the algorithm will not remove
  such points.

- output_path:

  character. A directory path. If `NULL` (default), the output is
  returned. Otherwise, the output of each `shape_id` is saved in this
  directory as an `.rds` file named after its `shape_id`, and nothing is
  returned. Characters that can't be in a file name on some systems
  (such as `/`, `:` or `*`) and `%` are written as `%XX`, their
  hexadecimal code, so
  [`utils::URLdecode()`](https://rdrr.io/r/utils/URLencode.html) gives
  the id back (e.g. `"a/b"` is saved as `a%2Fb.rds`). The whole feed is
  still processed in memory.
  [`emission_model()`](https://ipea.github.io/gtfs2emis/dev/reference/emission_model.md)
  reads every `.rds` file in this directory, so it should not contain
  files from other runs.

- continue:

  **Deprecated.** This argument is ignored, and using it gives a
  warning. The whole feed is processed at once.

## Value

An `sf` object (class `c("sf", "data.frame")`, CRS 4326) with one
LINESTRING per segment between consecutive stops, from the first to the
last stop of each trip, or `NULL` when `output_path` is provided (the
outputs are then saved as files in `output_path`). Its columns are:

- `shape_id`, `trip_id`, `route_type`, `trip_number`: the trip. For
  trips in `frequencies.txt`, `trip_id` gets a suffix for each departure
  (e.g. `"1054020_1"`, `"1054020_2"`);

- `from_stop_id`, `to_stop_id`, `stop_sequence`: the segment's stops;

- `from_timestamp`, `to_timestamp` (class `ITime`), and `timestamp`,
  equal to `from_timestamp`;

- `dist` (km) and `speed` (km/h) of the segment, and `cumdist` (m) and
  `cumtime` (s), cumulative along the trip, all as `units` objects;

- `geometry`.

## See also

Other Core function:
[`emission_model()`](https://ipea.github.io/gtfs2emis/dev/reference/emission_model.md)

## Examples

``` r
# \donttest{
if (requireNamespace("gtfstools", quietly=TRUE)) {

# read GTFS
gtfs_file <- system.file("extdata/bra_cur_gtfs.zip", package = "gtfs2emis")
gtfs <- gtfstools::read_gtfs(gtfs_file)

# keep a single trip_id to speed up this example
gtfs_small <- gtfstools::filter_by_trip_id(gtfs, trip_id ="4451136")

# run transport model
tp_model <- transport_model(
  gtfs_data = gtfs_small,
  min_speed = 2,
  max_speed = 80,
  new_speed = 20,
  spatial_resolution = 100,
  ncores = 2)

head(tp_model)

  }
#> ℹ Converting shapes to sf objects
#> Using 2 threads
#> ✔ Converting shapes to sf objects [22ms]
#> 
#> ℹ Processing the data
#> ✔ Processing the data [38ms]
#> 
#> Simple feature collection with 1 feature and 14 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -49.27058 ymin: -25.43893 xmax: -49.26813 ymax: -25.43349
#> Geodetic CRS:  WGS 84
#>   shape_id trip_id route_type timestamp stop_sequence         speed
#> 1     1999 4451136          3  19:29:00             1 26.715 [km/h]
#>            dist     cumdist     cumtime trip_number from_stop_id to_stop_id
#> 1 0.794018 [km] 794.018 [m] 106.998 [s]           1        25906      26028
#>   from_timestamp to_timestamp                       geometry
#> 1       19:29:00     19:30:47 LINESTRING (-49.26924 -25.4...
# }
```
