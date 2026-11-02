# Emissions from road vehicle tyre, brake, and surface wear from the European Environment Agency (EMEP/EEA) model

Returns a list or data.table of emissions for urban buses based on Tier
2 of EMEP/EEA air pollutant emission inventory guidebooks (2019). The
function concerns the emissions of particulate matter (PM), encompassing
black carbon (BC) (1), which arises from distinct sources, namely, road
vehicle tire and brake wear (NFR code 1.A.3.b.vi), and road surface wear
(NFR code 1.A.3.b.vii). It is important to note that PM emissions
exhaust from vehicle exhaust are excluded. The focus is on primary
particles, which refer to those that are directly emitted due to surface
wear, rather than those generated from the resuspension of previously
deposited material. See more in @details.

## Usage

``` r
emi_europe_emep_wear(
  dist,
  speed,
  pollutant,
  veh_type,
  fleet_composition,
  load = 0.5,
  process = "tyre",
  as_list = TRUE
)
```

## Arguments

- dist:

  units; Length of each link in 'km'.

- speed:

  units; Speed in 'km/h'.

- pollutant:

  character; Pollutant, classified in "TSP"(Total Suspended Particles),
  "PM10","PM2.5", "PM1.0","PM0.1". Please note that emissions factors
  for "PM1.0" and "PM0.1" are not available for road surface wear
  process.

- veh_type:

  character; Bus type, classified in "Ubus Midi \<=15 t", "Ubus Std 15 -
  18 t", "Ubus Artic \>18 t", "Coaches Std \>18 t", or "Coaches Artic
  \>18 t".

- fleet_composition:

  vector; Fleet composition, which is a distribution of fleet based on
  frequency. If there is only one, 'fleet_composition' is 1.0.

- load:

  numeric; Load ratio, classified in 0.0, 0.5 and 1.0. Default is 0.5.

- process:

  character; Emission process sources, classified in "tyre","brake"
  and/or "road".

- as_list:

  logical; Returns emission factors as a list, instead of data.table
  format. Default is TRUE.

## Value

List. emission in units 'g' (list or a data.table).

## Details

The following equation is employed to evaluate emissions originating
from tyre and brake wear

TE(i) = dist x EF_tsp(j) x mf_s(i) x sc(speed),

where:

- TE(i) = total emissions of pollutant i (g),

- dist = distance driven by each vehicle (km),

- EF_tsp(j) = TSP mass emission factor for vehicles of category j
  (g/km),

- mf_s(i) = mass fraction of TSP that can be attributed to particle size
  class i,

- sc(speed) = correction factor for a mean vehicle travelling at a given
  speed (-)

*Tyre*

In the case of heavy-duty vehicles, the emission factor needs the
incorporation of vehicle size, as determined by the number of axles, and
load. These parameters are introduced into the equation as follows:

EF_tsp_tyre_hdv = 0.5 x N_axle x LCF_tyre x EF_tsp_tyre_pc

where

- EF_tsp_tyre_hdv = TSP emission factor for tyre wear from heavy-duty
  vehicles (g/km),

- N_axle = number of vehicle axles (-),

- LCF_t = a load correction factor for tyre wear (-),

- EF_tsp_tyre_pc = TSP emission factor for tyre wear from passenger car
  vehicles (g/km).

and LCF_tyre = 1.41 + (1.38 x LF),

where:

- LF = load factor (-), ranging from 0 for an empty bus to 1 for a fully
  laden one.

The function considers the following look-up table for number of vehicle
axes:

|                      |                |
|----------------------|----------------|
| vehicle class (j)    | number of axes |
| Ubus Midi \<=15 t    | 2              |
| Ubus Std 15 - 18 t   | 2              |
| Ubus Artic \>18 t    | 3              |
| Coaches Std \<=18 t  | 2              |
| Coaches Artic \>18 t | 3              |

The size distribution of tyre wear particles are given by:

|                         |                      |
|-------------------------|----------------------|
| particle size class (i) | mass fraction of TSP |
| TSP                     | 1.000                |
| PM10                    | 0.600                |
| PM2.5                   | 0.420                |
| PM1.0                   | 0.060                |
| PM0.1                   | 0.048                |

Finally, the speed correction is:

sc_tyre(speed) = 1.39, when V \< 40 km/h; sc_tyre(speed) = -0.00974 x
speed + 1.78, when 40 \<= speed \<= 90 km/h; sc_tyre(speed) = 0.902,
when speed \> 90 km/h.

*Brake*

The heavy-duty vehicle emission factor is derived by modifying the
passenger car emission factor to conform to experimental data obtained
from heavy-duty vehicles.

EF_tsp_brake_hdv = 1.956 x LCF_brake x EF_tsp_brake_pc

where:

- EF_tsp_brake_hdv = heavy-duty vehicle emission factor for TSP,

- LCF_brake = load correction factor for brake wear,

- EF_tsp_brake_pc = passenger car emission factor for TSP,

and LCF_brake = 1 + (0.79 x LF),

where:

- LF = load factor (-), ranging from 0 for an empty bus to 1 for a fully
  laden one.

The size distribution of brake wear particles are given by:

|                         |                      |
|-------------------------|----------------------|
| particle size class (i) | mass fraction of TSP |
| TSP                     | 1.000                |
| PM10                    | 0.980                |
| PM2.5                   | 0.390                |
| PM1.0                   | 0.100                |
| PM0.1                   | 0.080                |

Finally, the speed correction is:

sc_brake(speed) = 1.67, when V \< 40 km/h; sc_brake(speed) = -0.0270 x
speed + 2.75, when 40 \<= speed \<= 95 km/h; sc_brake(speed) = 0.185,
when speed \> 95 km/h.

*Road Wear*

Emissions are calculated according to the equation:

TE(i) = dist x EF_tsp_road(j) x mf_road

where:

- TE = total emissions of pollutant i (g),

- dist = total distance driven by vehicles in category j (km),

- EF_tsp_road = TSP mass emission factor from road wear for vehicles j
  (0.0760 g/km),

- mf_road = mass fraction of TSP that can be attributed to particle size
  class i (-).

The following table shows the size distribution of road surface wear
particles

|                         |                      |
|-------------------------|----------------------|
| particle size class (i) | mass fraction of TSP |
| TSP                     | 1.00                 |
| PM10                    | 0.50                 |
| PM2.5                   | 0.27                 |

*References*

\#' EMEP/EEA data and reports can be accessed in the following links:

- 2019 edition
  <https://www.eea.europa.eu/en/analysis/publications/emep-eea-guidebook-2019/>.

## See also

Other Emission factor model:
[`ef_brazil_cetesb()`](https://ipeagit.github.io/gtfs2emis/dev/reference/ef_brazil_cetesb.md),
[`ef_europe_emep()`](https://ipeagit.github.io/gtfs2emis/dev/reference/ef_europe_emep.md),
[`ef_scaled_euro()`](https://ipeagit.github.io/gtfs2emis/dev/reference/ef_scaled_euro.md),
[`ef_usa_emfac()`](https://ipeagit.github.io/gtfs2emis/dev/reference/ef_usa_emfac.md),
[`ef_usa_moves()`](https://ipeagit.github.io/gtfs2emis/dev/reference/ef_usa_moves.md)

## Examples

``` r
emi_europe_emep_wear(dist = units::set_units(1,"km"),
                     speed =  units::set_units(30,"km/h"),
                     pollutant = c("PM10","TSP","PM2.5"),
                     veh_type = c("Ubus Std 15 - 18 t","Ubus Artic >18 t"),
                     fleet_composition = c(0.5,0.5),
                     load = 0.5,
                     process = c("brake","tyre","road"),
                     as_list = TRUE)
#> $pollutant
#> [1] "PM10"  "TSP"   "PM2.5"
#> 
#> $veh_type
#> [1] "Ubus Std 15 - 18 t" "Ubus Artic >18 t"  
#> 
#> $fleet_composition
#> [1] 0.5 0.5
#> 
#> $speed
#> 30 [km/h]
#> 
#> $dist
#> 1 [km]
#> 
#> $emi
#>    PM10_brake_veh_1 PM10_brake_veh_2 TSP_brake_veh_1 TSP_brake_veh_2
#>             <units>          <units>         <units>         <units>
#> 1:   0.01674622 [g]   0.01674622 [g]  0.01708798 [g]  0.01708798 [g]
#>    PM2.5_brake_veh_1 PM2.5_brake_veh_2 PM10_tyre_veh_1 PM10_tyre_veh_2
#>              <units>           <units>         <units>         <units>
#> 1:   0.006664313 [g]   0.006664313 [g]  0.00936999 [g]  0.01405498 [g]
#>    TSP_tyre_veh_1 TSP_tyre_veh_2 PM2.5_tyre_veh_1 PM2.5_tyre_veh_2
#>           <units>        <units>          <units>          <units>
#> 1: 0.01561665 [g] 0.02342497 [g]  0.006558993 [g]  0.009838489 [g]
#>    PM10_road_veh_1 PM10_road_veh_2 TSP_road_veh_1 TSP_road_veh_2
#>            <units>         <units>        <units>        <units>
#> 1:       0.019 [g]       0.019 [g]      0.038 [g]      0.038 [g]
#>    PM2.5_road_veh_1 PM2.5_road_veh_2
#>             <units>          <units>
#> 1:      0.01026 [g]      0.01026 [g]
#> 
#> $process
#> [1] "brake" "tyre"  "road" 
#> 
```
