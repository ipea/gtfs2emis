# Running exhaust emissions factors for buses from United States (MOVES3 model)

Returns a vector or data.frame of emission factors for urban buses based
on values from the [MOVES3 Model](https://www.epa.gov/moves). Emission
factor estimates are expressed in units 'g/km'.

## Usage

``` r
ef_usa_moves(
  pollutant,
  model_year,
  reference_year = 2020,
  speed,
  fuel = "D",
  as_list = TRUE
)
```

## Arguments

- pollutant:

  character. Pollutants: "CH4" (Methane), "CO" (Carbon Monoxide), "CO2"
  (Carbon Dioxide), "EC" (Energy Consumption), "HONO" (Nitrous Acid),
  "N2O" (Nitrous Oxide), "NH3" (Ammonia ), "NH4" (Ammonium), "NO"
  (Nitrogen Oxide), "NO2" (Nitrogen Dioxide), "NO3" (Nitrate), "NOx"
  (Oxides of Nitrogen), "PM10" (Primary Exhaust PM10 - Total), "PM25"
  (Primary Exhaust PM2.5 - Total), "SO2" (Sulfur Dioxide), "THC" (Total
  Gaseous Hydrocarbons ), "TOG" (Total Organic Gases) and "VOC"
  (Volatile Organic Compounds)

- model_year:

  numeric. Model year of vehicle.

- reference_year:

  numeric. Year of reference, in which the emissions inventory is
  estimated. Default is 2020. Values between 2015 - 2022.

- speed:

  units. Speed in 'km/h'. Emission factor are returned in speed
  intervals: "0-2.5", "2.5-7.5", "7.5-12.5", "12.5-17.5", "17.5-22.5",
  "22.5-27.5", "27.5-32.5", "32.5-37.5", "37.5-42.5", "42.5-47.5",
  "47.5-52.5", "52.5-57.5", "57.5-62.5", "62.5-67.5", "67.5-72.5",
  "\>72.5" mph (miles/h).

- fuel:

  character. Type of fuel: 'D' (Diesel),'G' (Gasoline), 'CNG'
  (Compressed Natural Gas). Default is 'D'.

- as_list:

  logical. If `TRUE` (default), the function returns the output in a
  `list` format. If `FALSE`, the output is returned in a `data.table`
  format.

## Value

List. Emission factors in units 'g/km' by speed and model_year.

## Details

Users can view the pre-processed database in `data(ef_usa_moves_db)`
function.

## See also

Other Emission factor model:
[`ef_brazil_cetesb()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_brazil_cetesb.md),
[`ef_europe_emep()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_europe_emep.md),
[`ef_scaled_euro()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_scaled_euro.md),
[`ef_usa_emfac()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_emfac.md),
[`emi_europe_emep_wear()`](https://ipea.github.io/gtfs2emis/dev/reference/emi_europe_emep_wear.md)

## Examples

``` r
df <- ef_usa_moves(
         pollutant = c("CO","PM10"),
         model_year = 2015,
         speed = units::set_units(10:100,"km/h"),
         reference_year = 2016,
         fuel = "D",
         as_list = TRUE
        )
```
