# Emission factors from California Air Resources Board (EMFAC Model)

Running exhaust emissions factors from [EMFAC2017
model](https://arb.ca.gov/emfac/emissions-inventory). The model
generates emission factors (EF) of urban buses in California (United
States), considering different pollutants, years of reference, model
year, fuel, speed ranges, type of regions, model version, and type of
season. Currently, the package supports EFs only for "Statewide" region
type, and "Annual" season. Specific data of other regions and seasons
can be download at \<<https://arb.ca.gov/emfac/emissions-inventory>\>.

## Usage

``` r
ef_usa_emfac_db
```

## Format

A data.table with 79198 rows and 8 variables:

- pol:

  Character; Pollutants: CH4(Methane), CO(Carbon Monoxide), CO2(Carbon
  Dioxide), N2O(Nitrous Oxide), NOx(Oxides of Nitrogen), PM10(Primary
  Exhaust PM10 - Total), PM25(Primary Exhaust PM2.5 - Total), SOX(Oxides
  of Sulfur), TOG(Total Organic Gases), ROG (Reactive Organic Gases)

- reference_year:

  Numeric; Year of reference between 2010 - 2020

- fuel:

  character; Type of fuel: 'D' (Diesel),'G' (Gasoline),'CNG' (Compressed
  Natural Gas).

- model_year:

  Model year.

- speed:

  Units; Speed in 'km/h'; Emission factor are returned in speed
  intervals such as "5-10", "10-15", "15-20", "20-25", "25-30", "30-35",
  "35-40", "40-45", "45-50" "50-55", "55-60", "60-65", "65-70", "70-75",
  "75-80", "80-85", "85-90", "\>90" mph (miles/h)

## Source

<https://arb.ca.gov/emfac/emissions-inventory>

## Details

The function returns the data in a data.frame format. The R script used
to process the raw EMFAC database can be found in the repository
\<<https://github.com/ipea/gtfs2emis/blob/master/data-raw/ef_usa_emfac_db.R>\>.

## See also

Other emission factor data:
[`ef_brazil_cetesb_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_brazil_cetesb_db.md),
[`ef_europe_emep_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_europe_emep_db.md),
[`ef_usa_moves_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_moves_db.md)
