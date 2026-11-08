# Emission factors from Environment Company of Sao Paulo, Brazil (CETESB)

units 'g/km'; Emission factors for buses based on estimates from the
Environment Company of Sao Paulo, Brazil (CETESB) 2017, and obtained
from [vein package](https://github.com/atmoschem/vein). The R script
used to organize the CETESB database can be found in the repository
\<<https://github.com/ipea/gtfs2emis/blob/master/data-raw/ef_brazil_cetesb_db.R>\>.

## Usage

``` r
ef_brazil_cetesb_db
```

## Format

A data.table:

- pollutant:

  character; Pollutants: "CH4", "CO2", "PM10", "N2O", "KML", "FC" (Fuel
  Consumption), "gD/KWH", "gCO2/KWH", "CO", "HC" (Total Hydrocarbon),
  "NMHC" (Non-Methane Hydrocarbon), "NOx", "NO2", "NO", "RCHO", "ETOH",
  "FS"(Fuel Sales) and "NH3"

- veh_type:

  character; Vehicle categories by fuel:"BUS_URBAN_D", "BUS_MICRO_D",
  "BUS_COACH_D" and "BUS_ARTIC_D".

- model_year:

  numeric; Filter the emission factor to start from a specific base
  year.

- as_list:

  logical; Returns emission factors as a list, instead of data.table
  format.

## See also

Other emission factor data:
[`ef_europe_emep_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_europe_emep_db.md),
[`ef_usa_emfac_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_emfac_db.md),
[`ef_usa_moves_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_moves_db.md)
