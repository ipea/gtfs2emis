# Running exhaust emissions factors for buses from Brazil (CETESB)

Returns a vector or `data.table` of emission factors for buses based on
estimates from the Environment Company of Sao Paulo, Brazil (CETESB)
2019. Emission factor estimates are expressed in units 'g/km'.

## Usage

``` r
ef_brazil_cetesb(pollutant, veh_type, model_year, as_list = TRUE)
```

## Arguments

- pollutant:

  character. Pollutants "CH4", "CO2", "PM10", "N2O", "NOx", "NO2", "NO",
  "KML" (Vehicle Kilometers Traveled), "FC" (Fuel Consumption), "gD/KWH"
  (grams of Diesel per kWh), "gCO2/KWH" (grams of CO2 per per kWh),
  "CO", "HC" (Total Hydrocarbon), "NMHC" (Non-Methane Hydrocarbon) and
  "NH3". "RCHO", "ETOH" and "FS" (Fuel Sales) are in
  `ef_brazil_cetesb_db` but have no values for buses, so they give an
  error.

- veh_type:

  character. Vehicle categories by fuel: "BUS_URBAN_D", "BUS_MICRO_D",
  "BUS_COACH_D" and "BUS_ARTIC_D".

- model_year:

  numeric. Vehicle model year, a whole number from 1960 to 2020.

- as_list:

  logical. If `TRUE` (default), the function returns the output in a
  `list` format. If `FALSE`, the output is returned in a `data.table`
  format.

## Value

data.table. Emission factors in units 'g/km' by model_year.

## Details

The new convention for vehicles names are translated from CETESB report:

|             |                                                   |
|-------------|---------------------------------------------------|
| vehicle     | description                                       |
| BUS_URBAN_D | Urban Bus Diesel (5perc bio-diesel)               |
| BUS_MICRO_D | Micro Urban Bus Diesel (5perc bio-diesel)         |
| BUS_COACH_D | Coach (inter-state) Bus Diesel (5perc bio-diesel) |
| BUS_ARTIC_D | Articulated Urban Bus Diesel (5perc bio-diesel)   |

The percentage varies of biofuels varies by law.

These emission factors are not exactly the same as the report of CETESB.

1.  In this emission factors, there is also NO and NO2 based on split by
    published in the EMEP/EEA air pollutant emission inventory
    guidebook.

2.  Also, the emission factors were extended till 50 years of use,
    repeating the oldest value.

## See also

Other Emission factor model:
[`ef_europe_emep()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_europe_emep.md),
[`ef_scaled_euro()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_scaled_euro.md),
[`ef_usa_emfac()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_emfac.md),
[`ef_usa_moves()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_moves.md),
[`emi_europe_emep_wear()`](https://ipea.github.io/gtfs2emis/dev/reference/emi_europe_emep_wear.md)

## Examples

``` r
df <- ef_brazil_cetesb(
          pollutant = c("CO","PM10","CO2","CH4","NOx"),
          veh_type = "BUS_URBAN_D",
          model_year = 2015,
          as_list = TRUE)
```
