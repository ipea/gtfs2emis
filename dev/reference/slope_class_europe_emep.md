# Add slope class into the transport model (LineString Simple Feature object)

Based on the input height data, the function returns the slope class
between two consecutive bus stop positions of a LineString Simple
Feature (transport model object). The slope is given by the ratio
between the height difference and network distance from two consecutive
public transport stops. The function classifies the slope into one of
the seven categories available on the European Environmental Agency
(EEA) database, which is -0.06, -0.04,-0.02, 0.00, 0.02, 0.04, and 0.06.
The classifications is described in @details .

## Usage

``` r
slope_class_europe_emep(tp_model, heightfile, keep = FALSE)
```

## Arguments

- tp_model:

  LineString Simple Feature; transport model output. Geometries must be
  LINESTRING and have a coordinate reference system; `dist` is in km.

- heightfile:

  character or raster data; The raster file with height data, or its
  filepath. Its coordinate reference system may differ from the one of
  `tp_model`.

- keep:

  A logical. Whether the columns related height and slope to the
  consecutive bus stops should be kept or dropped (defaults to FALSE,
  which keeps only the slope classification).

## Value

The transport model (`sf`) with all its columns and a `slope_class`
column.

## Slopes classification:

\| **slope interval** \| **slope class** \| \| slope \<= -0.070 \| -0.06
\| \| slope \> -0.070 & slope \<= -0.050 \| -0.06 \| \| slope \> -0.050
& slope \<= -0.030 \| -0.04 \| \| slope \> -0.030 & slope \<= -0.010 \|
-0.02 \| \| slope \> -0.010 & slope \<= +0.010 \| +0.00 \| \| slope \>
+0.010 & slope \<= +0.030 \| +0.02 \| \| slope \> +0.030 & slope \<=
+0.050 \| +0.04 \| \| slope \> +0.050 & slope \<= +0.070 \| +0.06 \| \|
slope \> +0.070 \| +0.06 \|

Heights are read at the first and last vertex of each segment, after
projecting them to the coordinate reference system of `heightfile`.
Segments with no height (outside the raster) are treated as flat (slope
0), with a warning.

## Examples

``` r
# \donttest{
 if (requireNamespace("gtfstools", quietly=TRUE)) {
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

# read raster file
raster_cur <- system.file("extdata/bra_cur-srtm.tif", package = "gtfs2emis")

tp_model_slope <- slope_class_europe_emep(tp_model,raster_cur)
}
#> Converting shapes to sf objects
#> Processing the data
# }
```
