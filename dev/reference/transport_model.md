# Transport model

This function converts a public transport data set in GTFS format into a
GPS-like table with the space-time positions and speeds of public
transport vehicles. The function also allow users to set the spatial
resolution of the output and to adjust the speed of public transport
vehicles given a `min_speed` and `max_speed` range.

## Usage

``` r
transport_model(
  gtfs_data,
  min_speed = 2,
  max_speed = 80,
  new_speed = NULL,
  parallel = TRUE,
  ncores = NULL,
  spatial_resolution = 100,
  output_path = NULL,
  continue = FALSE
)
```

## Arguments

- gtfs_data:

  A path to a GTFS file or a GTFS data organized as a list of
  `data.tables` created with
  [`gtfstools::read_gtfs()`](https://ipea.github.io/gtfstools/reference/read_gtfs.html).

- min_speed:

  numeric (in km/h) or a speed units value. Minimum speed to be
  considered as valid. Values below minimum speed will be updated
  according to the `new_speed` parameter, which can affect the arrival
  and departure times of vehicles at transit stops. Defaults to `2`
  km/h.

- max_speed:

  numeric (in km/h) or a speed units value. Maximum speed to be
  considered as valid. Values above maximum speed will be updated
  according to the `new_speed` parameter, which can affect the arrival
  and departure times of vehicles at transit stops. Defaults to `80`
  km/h.

- new_speed:

  numeric (in km/h) or a speed units value. Speed value used to replace
  the speeds that fall outside the `min_speed` and `max_speed` range or
  which are missing from the GTFS input. When `new_speed = NULL` (the
  default), the function uses the average speed of the entire GTFS data
  feed.

- parallel:

  logical. Decides whether the function should run in parallel. Defaults
  is `TRUE`.

- ncores:

  integer. Number of cores to be used in parallel execution. This
  argument is ignored if parallel is `FALSE`. Default (`NULL`) selects
  the total number of available cores minus one.

- spatial_resolution:

  The spatial resolution in meters. Defaults to `100`. The function only
  creates points in order to guarantee that the maximum distance between
  two consecutive points will be at most the `spatial_resolution` value.
  If a given GTFS shape_id has two consecutive points with a distance
  smaller than the spatial resolution, the algorithm will not remove
  such points.

- output_path:

  character. A directory path. If `NULL` (Default), the function returns
  the output. If the user passes a valid `output_path`, the output will
  be saved in the `output_path` dir. Note that the output of each public
  transport `shape_id` is saved separately in different files. Setting
  an `output_path` is recommended when working with large public
  transport system because the output of the function can be
  significantly large.

- continue:

  logical. Argument that can be used only with output_path When TRUE, it
  skips processing the shape identifiers that were already saved into
  files. It is useful to continue processing a GTFS file that was
  stopped for some reason. Default value is FALSE.

## Value

An `sf` object (class `c("sf", "data.frame")`) with one LINESTRING per
segment between consecutive stops, or `NULL` when `output_path` is
provided (the outputs are then saved as files in `output_path`).

## See also

Other Core function:
[`emission_model()`](https://ipeagit.github.io/gtfs2emis/dev/reference/emission_model.md)

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
tp_model <- transport_model(gtfs_data = gtfs_small,
                            min_speed = 2,
                            max_speed = 80,
                            new_speed = 20,
                            spatial_resolution = 100,
                            parallel = FALSE)
  }
#> Converting shapes to sf objects
#> Processing the data
# }
```
