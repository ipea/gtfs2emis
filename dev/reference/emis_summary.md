# Summarize emissions estimates

Summarize emissions estimates, aggregating emissions by pollutant, time
of the day, vehicle.

## Usage

``` r
emis_summary(
  emi_list,
  by = "pollutant",
  veh_vars = "veh_type",
  segment_vars = NULL,
  process_vars = "process"
)
```

## Arguments

- emi_list:

  list. Emission or emission factor list.

- by:

  character. Emissions can be aggregated by 'time', 'vehicle', or simply
  'pollutant' (Default).

- veh_vars:

  character. data.frame names of 'emi_list' attributed to vehicle
  characteristics. Default is 'veh_type'.

- segment_vars:

  character. data.frame names of 'emi_list' object attributed to the
  road segments. Default is NULL.

- process_vars:

  character. data.frame names of 'emi_list' object attributed to the
  emission processes. Default is 'process'.

## Value

`data.table` with pollutants units ('g') aggregated by pollutant, time,
or vehicle type.

## See also

Other emission analysis:
[`emis_grid()`](https://ipeagit.github.io/gtfs2emis/dev/reference/emis_grid.md),
[`emis_to_dt()`](https://ipeagit.github.io/gtfs2emis/dev/reference/emis_to_dt.md)

## Examples

``` r
# \donttest{
if (requireNamespace("gtfstools", quietly=TRUE)) {

# read GTFS
gtfs_file <- system.file("extdata/irl_dub_gtfs.zip", package = "gtfs2emis")
gtfs <- gtfstools::read_gtfs(gtfs_file)

# Keep a single trip
gtfs <- gtfstools::filter_by_trip_id(gtfs
                                     , trip_id = c('238.2.60-118-b12-1.59.I'
                                                   ,"7081.2.60-X27-b12-1.106.I"))
# Transport model
tp_model <- transport_model(gtfs_data = gtfs,
                            spatial_resolution = 100,
                            parallel = FALSE)

# fleet data
fleet_df <- read.csv(system.file("extdata/irl_dub_fleet.txt"
                                 , package = "gtfs2emis"))
# emission model
emi_list <- emission_model(tp_model = tp_model
                           , ef_model = "ef_europe_emep"
                           , fleet_data = fleet_df
                           , pollutant = c("CO2","PM10"))

# Aggregate total emissions by 'pollutant'
emis_summary(emi_list) 

# by vehicle type
emis_summary(emi_list, by = "vehicle")
             
emis_summary(emi_list
             , by = "vehicle"
             , veh_vars = c("euro"))

emis_summary(emi_list
             , by = "vehicle"
             , veh_vars = c("fuel"))

emis_summary(emi_list
             , by = "vehicle"
             , veh_vars = c("veh_type","euro","tech","fuel"))
             
# by time of the day
emis_summary(emi_list
             , by = "time"
             , segment_vars = "slope") 
}
#> Converting shapes to sf objects
#> Processing the data
#>    timestamp_hour pollutant     process              emi
#>             <int>    <char>      <char>          <units>
#> 1:              8       CO2 hot_exhaust 1.076303e+04 [g]
#> 2:              8      PM10 hot_exhaust 3.509064e-01 [g]
#> 3:              9       CO2 hot_exhaust 8.952295e+01 [g]
#> 4:              9      PM10 hot_exhaust 3.022266e-03 [g]
# }
```
