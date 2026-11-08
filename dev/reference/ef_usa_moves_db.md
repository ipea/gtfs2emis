# Emission factors from MOtor Vehicle Emission Simulator (MOVES) Data.frame of emission factors for buses based on values from the [MOVES3 Model](https://www.epa.gov/moves). Estimates expressed in units 'g/km'.

Emission factors from MOtor Vehicle Emission Simulator (MOVES)

Data.frame of emission factors for buses based on values from the
[MOVES3 Model](https://www.epa.gov/moves). Estimates expressed in units
'g/km'.

## Usage

``` r
ef_usa_moves_db
```

## Format

A data.table:

- pollutant:

  character; Pollutants: CH4 (Methane), CO (Carbon Monoxide), CO2
  (Carbon Dioxide), EC (Energy Consumption), HONO (Nitrous Acid), N2O
  (Nitrous Oxide), NH3 (Ammonia), NH4 (Ammonium), NO (Nitrogen Oxide),
  NO2 (Nitrogen Dioxide), NO3 (Nitrate), NOx (Oxides of Nitrogen), PM10
  (Primary Exhaust PM10 - Total), PM25 (Primary Exhaust PM2.5 - Total),
  SO2 (Sulfur Dioxide), THC (Total Gaseous Hydrocarbons ), TOG (Total
  Organic Gases) and VOC (Volatile Organic Compounds)

- fuel_type:

  character; Type of fuel: 'D' (Diesel),'G' (Gasoline),'CNG' (Compressed
  Natural Gas).

- reference_year:

  Numeric; Calendar Year between 2015 - 2022. Year in which the
  emissions inventory is estimated.

- model_year:

  numeric; Model year of vehicle.

- lower_speed_interval:

  units 'km/h'; Represents the lower value of the speed intervals; The
  speed intervals are " - 2.5", "2.5 - 7.5", "7.5 - 12.5" , "12.5 -
  17.5", "17.5 - 22.5", "22.5 - 27.5","27.5 - 32.5","32.5 - 37.5"
  ,"37.5 - 42.5","42.5 - 47.5","47.5 - 52.5","52.5 - 57.5", "57.5 -
  62.5" , "62.5 - 67.5", "67.5 - 72.5", and "\>72.5" mph (miles/h).

- upper_speed_interval:

  units in km/h; Represents the upper value of the speed intervals. The
  speed intervals are analogous to `lower_speed_interval` above.

- source_type:

  character; Type of vehicle, which currently has only "Transit Bus".

- id_speed:

  integer;it caracterizes the types of vehicle speeds.

## Source

<https://www.epa.gov/moves>

## See also

Other emission factor data:
[`ef_brazil_cetesb_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_brazil_cetesb_db.md),
[`ef_europe_emep_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_europe_emep_db.md),
[`ef_usa_emfac_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_emfac_db.md)
