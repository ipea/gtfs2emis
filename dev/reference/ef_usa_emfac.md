# Running exhaust emissions factors for buses from United States (EMFAC2017 model)

Returns a vector or data.frame of emission factors for buses based on
the [California EMission Factor model
(EMFAC2017)](https://arb.ca.gov/emfac/). The model considers emission
factors (EF) of urban buses in California (United States), considering
different pollutants, years of reference, model year, fuel, speed
ranges, type of regions, model version, and type of season. The
gtfs2emis package currently supports EF only for "Statewide" region
type, and "Annual" season. Specific data of these variables can be
download at \<<https://arb.ca.gov/emfac/emissions-inventory>\>.

## Usage

``` r
ef_usa_emfac(
  pollutant,
  reference_year = 2020,
  fuel = "D",
  model_year,
  speed,
  as_list = TRUE
)
```

## Source

<https://arb.ca.gov/emfac/>

## Arguments

- pollutant:

  character. Pollutants: "CH4" (Methane), "CO" (Carbon Monoxide), "CO2"
  (Carbon Dioxide), "N2O" (Nitrous Oxide), "NOx" (Oxides of Nitrogen),
  "PM10" (Primary Exhaust PM10 - Total), "PM25" (Primary Exhaust PM2.5 -
  Total), "SOX" (Oxides of Sulfur), "TOG" (Total Organic Gases), "ROG"
  (Reactive Organic Gases).

- reference_year:

  numeric. Year of reference, in which the emissions inventory is
  estimated. Default is 2020. Values between 2015 - 2022.

- fuel:

  character. Type of fuel: 'D' (Diesel),'G' (Gasoline), 'CNG'
  (Compressed Natural Gas). Default is 'D'.

- model_year:

  Numeric; Model year of vehicle.

- speed:

  Units. Speed in 'km/h'; Emission factor are returned in speed
  intervals: "5-10", "10-15", "15-20", "20-25", "25-30", "30-35",
  "35-40", "40-45", "45-50", "50-55", "55-60", "60-65", "65-70",
  "70-75", "75-80", "80-85", "85-90", "\>90" mph (miles/h).

- as_list:

  logical. If `TRUE` (default), the function returns the output in a
  `list` format. If `FALSE`, the output is returned in a `data.table`
  format.

## Value

List or data.table. Emission factors in units 'g/km' by speed and
model_year.

## See also

Other Emission factor model:
[`ef_brazil_cetesb()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_brazil_cetesb.md),
[`ef_europe_emep()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_europe_emep.md),
[`ef_scaled_euro()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_scaled_euro.md),
[`ef_usa_moves()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_moves.md),
[`emi_europe_emep_wear()`](https://ipea.github.io/gtfs2emis/dev/reference/emi_europe_emep_wear.md)

## Examples

``` r
df <- ef_usa_emfac(
        pollutant = c("CO","PM10"),
        reference_year = 2019,
        model_year = 2015,
        speed = units::set_units(10:100,"km/h"),
        fuel = "D",
        as_list = TRUE
        )
```
