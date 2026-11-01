# Preparing fleet data for gtfs2emis

## 1. Introduction

When using the `gtfs2emis` package to estimate the emission levels of a
given public transport system, users are required to input `data.frame`
with a few characteristics of the public transport fleet, such as age or
vehicle type. This vignette explains how users can build this input by
showing practical examples for fleet data in Brazilian, European, and
North American cities.

## 2. Simple or detailed fleet data table

The first thing to have in mind is that the fleet `data.frame` can be
either:

- A **simple** table with the overall composition of the fleet. In this
  case, the `gtfs2emis` will assume that fleet is homogeneously
  distributed across all routes; OR
- A **detailed** table that brings info on the proportion with which
  each vehicle type is allocated to each transport route.

#### Example of *simple* fleet table

Here is an example of a simple fleet table that tells us the
characteristics of the urban buses of Dublin, Ireland. The `N` and
`fleet_composition` columns tell us, respectively, the absolute number
and the proportion of buses with each combination of the following
characteristics: vehicle type, Euro standard, technology, and fuel. Note
that `sum(fleet_df$fleet_composition)` has to be equal to 1.

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

#### Example of *detailed* fleet table

This other table illustrates what a detailed fleet data table looks
like, using the example of the city of Curitiba, Brazil. Here, the `N`
column also tells us the absolute number of buses with each combination
of vehicle characteristics. However, note that this table brings a
`shape_id` column. These columns indicate which specific vehicles should
be allocated to run on predefined `shape_id`s of the GTFS data. For
example, it allows users to assign articulated buses to specific routes
in the transport network.

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

Please note that the columns in your fleet data table should differ
depending on the data requirements of the emission factor model the user
wants to consider. For example, the emission factor models for US cities
(EMFAC2017 and MOVES3), developed by CARB and EPA, only require
information on the type of bus, the fuel used, and age of the vehicle.
Meanwhile, the EMEP model developed by the European Environment Agency
requires much more info, including vehicle type, Euro standard,
technology, and fuel. It also allows users to consider the passenger
load and slope of streets.

To check which columns and sets of vehicle characteristics are required
by each emission factor model, the user can read the documentation of
the emission factor functions listed in the table below:

| Emission factor function | Region | Source | Type of buses | Other required characteristics |
|----|----|----|----|----|
| [`ef_brazil_cetesb()`](https://ipeagit.github.io/gtfs2emis/reference/ef_brazil_cetesb.md) | Brazil | CETESB | Micro, Standard, Articulated | Age, Fuel, EURO stage |
| [`ef_europe_emep()`](https://ipeagit.github.io/gtfs2emis/reference/ef_europe_emep.md) | Europe | EMEP/EEA | Micro, Standard, Articulated | Fuel, EURO stage, technology, load, slope |
| [`ef_usa_moves()`](https://ipeagit.github.io/gtfs2emis/reference/ef_usa_moves.md) | US | EMFAC2017/CARB | Urban Buses | Age, Fuel |
| [`ef_usa_emfac()`](https://ipeagit.github.io/gtfs2emis/reference/ef_usa_emfac.md) | US | MOVES3/EPA | Urban Buses | Age, Fuel |

## 4. Examples of fleet data tables

Now here are a few examples of `data.frames` with the fleet
characteristics required by different emission factor models. Note that
these examples are built as a simple fleet table that includes the
`fleet_composition`, indicating what proportion of the fleet is
represented by vehicles with each characteristic.

### 4.1 Brazil: Environmental Company of Sao Paulo (CETESB):

Based on the 2019 data from the emission factor model of CETESB.

``` r

fleet_data_ef_cetesb <- data.frame( veh_type = c("BUS_MICRO_D", "BUS_URBAN_D", "BUS_ARTIC_D")
                                  , model_year = c(2010, 2012, 2018)
                                  , fuel = rep("D", 3)
                                  , fleet_composition = c(0.4, 0.4, 0.2))
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

fleet_data_ef_europe <- data.frame(  veh_type = c("Ubus Midi <=15 t"
                                                  ,"Ubus Std 15 - 18 t"
                                                  ,"Ubus Artic >18 t")
                                   , euro = c("III","IV","V")
                                   , fuel = rep("D",3)
                                   , tech = c("-","SCR","SCR")
                                   , fleet_composition = c(0.4,0.5,0.1)) #
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

fleet_data_ef_emfac <- data.frame(  veh_type = "BUS_URBAN_D"
                                  , model_year = 2011:2015
                                  , fuel = "D"
                                  , calendar_year = 2019
                                  , fleet_composition = rep(0.2,5))
fleet_data_ef_emfac
#>      veh_type model_year fuel calendar_year fleet_composition
#> 1 BUS_URBAN_D       2011    D          2019               0.2
#> 2 BUS_URBAN_D       2012    D          2019               0.2
#> 3 BUS_URBAN_D       2013    D          2019               0.2
#> 4 BUS_URBAN_D       2014    D          2019               0.2
#> 5 BUS_URBAN_D       2015    D          2019               0.2
```

### 4.4 United States: MOVES3 - Environmental Protection Agency (EPA)

Based on the Motor Vehicle Emission Simulator ([MOVES3
Model](https://www.epa.gov/moves)), developed by EPA.

``` r

fleet_data_ef_moves <- data.frame(  veh_type = "BUS_URBAN_D"
                                  , model_year = 2011:2015
                                  , fuel = "D"
                                  , calendar_year = 2016
                                  , fleet_composition = rep(0.2,5))
fleet_data_ef_moves
#>      veh_type model_year fuel calendar_year fleet_composition
#> 1 BUS_URBAN_D       2011    D          2016               0.2
#> 2 BUS_URBAN_D       2012    D          2016               0.2
#> 3 BUS_URBAN_D       2013    D          2016               0.2
#> 4 BUS_URBAN_D       2014    D          2016               0.2
#> 5 BUS_URBAN_D       2015    D          2016               0.2
```

### Learn more

Check out our extra guide:

- [Exploring Emission
  Factors](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_emission_factor.html)
- [Exploring Non-Exhaust Emission
  Factors](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_non_exhaust_ef.html)

### Report a bug

If you have any suggestions or want to report an error, please visit
[the package GitHub page](https://github.com/ipeaGIT/gtfs2emis/issues).
