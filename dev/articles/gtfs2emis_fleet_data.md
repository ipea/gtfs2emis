# Preparing fleet data for gtfs2emis

## 1. Introduction

To estimate emissions with `gtfs2emis`, you need a `data.frame`
describing the public transport fleet, for example its vehicle types and
ages. This vignette shows how to build it, with examples for Brazilian,
European and North American cities.

## 2. Simple or detailed fleet data table

The fleet `data.frame` can be either:

- a **simple** table with the overall composition of the fleet, in which
  case `gtfs2emis` assumes the fleet is evenly distributed across all
  routes; or
- a **detailed** table that also says which vehicles run on which
  routes.

#### Example of a *simple* fleet table

This simple table describes the urban buses of Dublin, Ireland. The `N`
and `fleet_composition` columns give, respectively, the number and the
share of buses for each combination of vehicle type, Euro standard,
technology and fuel. `fleet_composition` must sum to 1.

``` r

simple_fleet_file <- system.file("extdata/irl_dub_fleet.txt", package = "gtfs2emis")
simple_fleet_df <- read.csv(simple_fleet_file)
head(simple_fleet_df)
#>             veh_type euro fuel   N fleet_composition    tech
#> 1 Ubus Std 15 - 18 t  III    D  10        0.00998004       -
#> 2 Ubus Std 15 - 18 t   IV    D 296        0.29540918     SCR
#> 3 Ubus Std 15 - 18 t    V    D 148        0.14770459     SCR
#> 4 Ubus Std 15 - 18 t   VI    D 548        0.54690619 DPF+SCR
```

#### Example of a *detailed* fleet table

This detailed table describes buses in Curitiba, Brazil. The `total`
column gives the number of buses for each combination of vehicle
characteristics, and the `shape_id` column says which GTFS `shape_id`
they run on.

[`emission_model()`](https://ipea.github.io/gtfs2emis/dev/reference/emission_model.md)
does not read `shape_id`: it applies the `fleet_composition` of the
fleet data to every segment of `tp_model`. To use route-specific fleets
(for example, articulated buses only on the routes where they run),
split `tp_model` by `shape_id`, compute a `fleet_composition` for each
group from the detailed table, and call
[`emission_model()`](https://ipea.github.io/gtfs2emis/dev/reference/emission_model.md)
once per group.

``` r

detailed_fleet_file <- system.file("extdata/bra_cur_fleet.txt", package = "gtfs2emis")
detailed_fleet_df <- read.csv(detailed_fleet_file)
head(detailed_fleet_df)
#>   year euro shape_id type_name_br           veh_type total fuel
#> 1 2006  III     1849  BUS_URBAN_D Ubus Std 15 - 18 t     2    D
#> 2 2011  III     1849  BUS_URBAN_D Ubus Std 15 - 18 t     4    D
#> 3 2018    V     1733  BUS_MICRO_D   Ubus Midi <=15 t     1    D
#> 4 2011  III     1735  BUS_URBAN_D Ubus Std 15 - 18 t     3    D
#> 5 2018    V     1735  BUS_MICRO_D   Ubus Midi <=15 t     2    D
#> 6 2008  III     1735  BUS_MICRO_D   Ubus Midi <=15 t     2    D
```

## 3. Fleet characteristics vary by emission factor model

The columns of the fleet table depend on the emission factor model.
Every model needs `veh_type` and `fleet_composition`. The US models
(EMFAC2017 by CARB and MOVES3 by EPA) also need `model_year` and `fuel`.
The European EMEP/EEA model also needs `euro`, `tech` and `fuel`; road
slope can be added with the `heightfile` argument of
[`emission_model()`](https://ipea.github.io/gtfs2emis/dev/reference/emission_model.md).

The table below summarises what each model needs; the documentation of
each function has the details:

| Emission factor function | Region | Source | Type of buses | Other required characteristics |
|----|----|----|----|----|
| [`ef_brazil_cetesb()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_brazil_cetesb.md) | Brazil | CETESB | Micro, Standard, Articulated | Age |
| [`ef_europe_emep()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_europe_emep.md) | Europe | EMEP/EEA | Micro, Standard, Articulated | Fuel, Euro stage, technology (slope optional) |
| [`ef_usa_moves()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_moves.md) | US | MOVES3/EPA | Urban Buses | Age, Fuel |
| [`ef_usa_emfac()`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_emfac.md) | US | EMFAC2017/CARB | Urban Buses | Age, Fuel |

## 4. Examples of fleet data tables

Below are simple fleet tables for each emission factor model. In each
one, `fleet_composition` gives the share of the fleet with each
combination of characteristics.

### 4.1 Brazil: Environmental Company of São Paulo (CETESB)

Based on the 2019 CETESB emission factors.

``` r

fleet_data_ef_cetesb <- data.frame(veh_type = c("BUS_MICRO_D", "BUS_URBAN_D", "BUS_ARTIC_D"),
                                   model_year = c(2010, 2012, 2018),
                                   fuel = rep("D", 3),
                                   fleet_composition = c(0.4, 0.4, 0.2))
fleet_data_ef_cetesb
#>      veh_type model_year fuel fleet_composition
#> 1 BUS_MICRO_D       2010    D               0.4
#> 2 BUS_URBAN_D       2012    D               0.4
#> 3 BUS_ARTIC_D       2018    D               0.2
```

### 4.2 Europe: EMEP - European Environment Agency (EEA)

Based on the European Monitoring and Evaluation Programme
([EMEP](https://www.eea.europa.eu/en/analysis/publications/emep-eea-guidebook-2019/part-b-sectoral-guidance-chapters/1-energy/)),
developed by EEA.

``` r

fleet_data_ef_europe <- data.frame(veh_type = c("Ubus Midi <=15 t",
                                                 "Ubus Std 15 - 18 t",
                                                 "Ubus Artic >18 t"),
                                   euro = c("III", "IV", "V"),
                                   fuel = rep("D", 3),
                                   tech = c("-", "SCR", "SCR"),
                                   fleet_composition = c(0.4, 0.5, 0.1))
fleet_data_ef_europe
#>             veh_type euro fuel tech fleet_composition
#> 1   Ubus Midi <=15 t  III    D    -               0.4
#> 2 Ubus Std 15 - 18 t   IV    D  SCR               0.5
#> 3   Ubus Artic >18 t    V    D  SCR               0.1
```

### 4.3 United States: EMFAC2017 - California Air Resources Board (CARB)

Based on the California Emission Factor model
([EMFAC2017](https://arb.ca.gov/emfac/)), developed by CARB.

``` r

fleet_data_ef_emfac <- data.frame(veh_type = "BUS_URBAN_D",
                                  model_year = 2011:2015,
                                  fuel = "D",
                                  fleet_composition = rep(0.2, 5))
fleet_data_ef_emfac
#>      veh_type model_year fuel fleet_composition
#> 1 BUS_URBAN_D       2011    D               0.2
#> 2 BUS_URBAN_D       2012    D               0.2
#> 3 BUS_URBAN_D       2013    D               0.2
#> 4 BUS_URBAN_D       2014    D               0.2
#> 5 BUS_URBAN_D       2015    D               0.2
```

### 4.4 United States: MOVES3 - Environmental Protection Agency (EPA)

Based on the Motor Vehicle Emission Simulator ([MOVES3
Model](https://www.epa.gov/moves)), developed by EPA.

``` r

fleet_data_ef_moves <- data.frame(veh_type = "BUS_URBAN_D",
                                  model_year = 2011:2015,
                                  fuel = "D",
                                  fleet_composition = rep(0.2, 5))
fleet_data_ef_moves
#>      veh_type model_year fuel fleet_composition
#> 1 BUS_URBAN_D       2011    D               0.2
#> 2 BUS_URBAN_D       2012    D               0.2
#> 3 BUS_URBAN_D       2013    D               0.2
#> 4 BUS_URBAN_D       2014    D               0.2
#> 5 BUS_URBAN_D       2015    D               0.2
```

For both US models, the year of the emission inventory is not a column
of the fleet data: it is set with the `reference_year` argument of
[`emission_model()`](https://ipea.github.io/gtfs2emis/dev/reference/emission_model.md).

### Learn more

Check out our other guides:

- [Exploring Emission
  Factors](https://ipea.github.io/gtfs2emis/articles/gtfs2emis_emission_factor.html)
- [Exploring Non-Exhaust Emission
  Factors](https://ipea.github.io/gtfs2emis/articles/gtfs2emis_non_exhaust_ef.html)

### Report a bug

If you have any suggestions or want to report an error, please visit
[the package GitHub page](https://github.com/ipea/gtfs2emis/issues).
