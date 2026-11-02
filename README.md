# gtfs2emis: Estimating public transport emissions from GTFS data <img src="man/figures/logo.png" alt="logo" align="right" width="180"/>

[![CRAN/METACRAN
Version](https://www.r-pkg.org/badges/version/gtfs2emis)](https://CRAN.R-project.org/package=gtfs2emis)
[![CRAN/METACRAN Total
downloads](https://cranlogs.r-pkg.org/badges/grand-total/gtfs2emis?color=blue)](https://CRAN.R-project.org/package=gtfs2emis)
[![R-CMD-check](https://github.com/ipeaGIT/gtfs2emis/workflows/R-CMD-check/badge.svg)](https://github.com/ipeaGIT/gtfs2emis/actions)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![Codecov test
coverage](https://codecov.io/gh/ipeaGIT/gtfs2emis/branch/master/graph/badge.svg)](https://app.codecov.io/gh/ipeaGIT/gtfs2emis?branch=master)
[![DOI](https://img.shields.io/badge/DOI-10.1016/j.trd.2023.103757-blue)](https://doi.org/10.1016/j.trd.2023.103757)

**gtfs2emis** is an R package to estimate the emission levels of public
transport vehicles based on General Transit Feed Specification (GTFS)
data. The package requires two main inputs: i) public transport data in
GTFS standard format; and ii) some basic information on fleet
characteristics such as vehicle age, technology, fuel, and Euro stage.
As it stands, the package estimates several pollutants (see table below)
at high spatial and temporal resolutions. Pollution levels can be
calculated for specific transport routes, trips, time of the day, or for
the transport system as a whole. The output with emission estimates can
be extracted in different formats, supporting analysis of how emission
levels vary across space, time, and by fleet characteristics. A full
description of the methods used in the gtfs2emis model is presented in
[Vieira, Pereira and Andrade
(2023)](https://doi.org/10.1016/j.trd.2023.103757).

## Installation

You can install `gtfs2emis`:

``` r
# From CRAN
install.packages("gtfs2emis")
library(gtfs2emis)

# or use the development version with latest features
devtools::install_github("ipeaGIT/gtfs2emis")
library(gtfs2emis)
```

## Usage and Data requirements

The `gtfs2emis` package has two core functions.

1.  `transport_model()` converts GTFS data into a GPS-like table with
    the space-time positions and speeds of public transport vehicles.
    The only input required is a `GTFS.zip` feed.

2.  `emission_model()` estimates hot-exhaust emissions based on four
    inputs:

-   1)  the result from the `transport_model()`;
-   2)  a `data.frame` with info on fleet characteristics;
-   3)  a `string` indicating which emission factor model should be considered;
-   4)  a `string` indicating which pollutants should be estimated.

To help users analyze the output from `emission_model()`, the
`gtfs2emis` package has few functions:

3.  `emis_to_dt()` to convert the output of `emission_model()` from
    `list` to `data.table`.
4.  `emis_summary()` to aggregate emission estimates by the time of the
    day, vehicle type, or road segment.
5.  `emis_grid()` to spatially aggregate emission estimates using any
    custom spatial grid or polygons.

## Demonstration on sample data

To illustrate functionality, the package includes small sample data sets
of the public transport and fleet of Curitiba (Brazil), Detroit (USA),
and Dublin (Ireland). Estimating the emissions of a given public
transport system using `gtfs2emis` can be done in three simple steps, as
follows.

### 1. Run transport model

The first step is to use the `transport_model()` function to convert
GTFS data into a GPS-like table, so that we can get the space-time
position and speed of each vehicle of the public transport system at
high spatial and temporal resolutions.

``` r
# read GTFS.zip
gtfs_file <- system.file("extdata/irl_dub_gtfs.zip", package = "gtfs2emis")
gtfs <- gtfstools::read_gtfs(gtfs_file)

# generate transport model
tp_model <- transport_model(gtfs_data = gtfs,spatial_resolution = 100,parallel = TRUE) 
```

### 2. Prepare fleet data

The second step is to prepare a `data.frame` with some characteristics
of the public transport fleet. Note that different emission factor
models may require information on different fleet characteristics, such
as vehicle age, type, Euro standard, technology, and fuel. This can be
either: - A simple table with the overall composition of the fleet. In
this case, the `gtfs2emis` will assume that fleet is homogeneously
distributed across all routes; OR - A detailed table that (1) brings
info on the characteristics of each vehicle and, (2) tells the
probability with which each vehicle type is allocated to each transport
route.

Here is what a simple fleet table to be used with the EMEP-EEA emission
factor model looks like:

``` r
fleet_file <- system.file("extdata/irl_dub_fleet.txt", package = "gtfs2emis")

fleet_df <- read.csv(fleet_file)
fleet_df
#>             veh_type euro fuel   N fleet_composition    tech
#> 1 Ubus Std 15 - 18 t  III    D  10        0.00998004       -
#> 2 Ubus Std 15 - 18 t   IV    D 296        0.29540918     SCR
#> 3 Ubus Std 15 - 18 t    V    D 148        0.14770459     SCR
#> 4 Ubus Std 15 - 18 t   VI    D 548        0.54690619 DPF+SCR
```

### 3. Run emission model

In the final step, the `emission_model()` function to estimate hot
exhaust emissions of our public transport system. Here, the user needs
to pass the results from `transport_model()`, some fleet data as
described above, and select which emission factor model and pollutants
should be considered (see the options available below). The output from
`emission_model()` is a `list` with several `vectors` and `data.frames`
with emission estimates and related information such as vehicle
variables (`veh_type`, `euro`, `fuel`, `tech`, `fleet_composition`),
travel variables (`slope`, `load`, `speed`, `tp_model`) or pollution
(`EF`, `emi`).

``` r
emi_list <- emission_model(tp_model = tp_model
, ef_model = "ef_europe_emep"
, fleet_data = fleet_df
, pollutant = c("NOx","PM10")
)

names(emi_list)
#>  [1] "pollutant"         "veh_type"          "euro"             
#>  [4] "fuel"              "tech"              "process"          
#>  [7] "slope"             "load"              "speed"            
#> [10] "EF"                "emi"               "tp_model"         
#> [13] "fleet_composition"
```

## Emission factor models and pollutants available

Currently, the `gtfs2emis` package provides a computational method to
estimate running exhaust emissions factors based on the following
emission factor models:

-   Brazil
    -   CETESB: 2019 model from the Environmental Company of Sao Paulo (CETESB)
-   Europe
    -   [EMEP/EEA](https://www.eea.europa.eu/en/analysis/publications/emep-eea-guidebook-2019):
        European Monitoring and Evaluation Programme, developed by the
        European Environment Agency (EEA).
-   United States
    -   [EMFAC2017/CARB](https://arb.ca.gov/emfac/): California Emission
        Factor model, developed by the California Air Resources Board
        (CARB).
    -   [MOVES3/EPA](https://www.epa.gov/moves): Vehicle Emission
        Simulator, developed by the Environmental Protection Agency
        (EPA).

#### List of pollutants available by emission factor models

| Source         | Pollutants                                                                                                                         |
|--------------|----------------------------------------------------------|
| CETESB         | CH4, CO, CO2, ETOH, FC (Fuel Consumption), FS (Fuel Sales), gCO2/KWH, gD/KWH, HC, KML, N2O, NH3, NMHC, NO, NO2, NOx, PM10 and RCHO |
| EMFAC2017/CARB | CH4, CO, CO2, N2O, NOx, PM10, PM25, ROG (Reactive Organic Gases), SOX, and TOG (Total Organic Gases)                               |
| EMEP/EEA       | CH4, CO, CO2, EC, FC, N2O, NH3, NOx, PM10, SPN23 (#kWh), and VOC                                                                   |
| MOVES3/EPA     | CH4, CO, CO2, EC, HONO, N2O, NH3, NH4, NO, NO2, NO3, NOx, PM10, PM25, SO2, THC, TOG, and VOC                                       |

#### Fleet characteristics required by each emission factor model

| Source         | Buses                        | Characteristics                              |
|-----------------|----------------------|----------------------------------|
| CETESB         | Micro, Standard, Articulated | Age, Fuel, EURO standard                     |
| EMEP/EEA       | Micro, Standard, Articulated | Fuel, EURO standard, technology, load, slope |
| EMFAC2017/CARB | Urban Buses                  | Age, Fuel                                    |
| MOVES3/EPA     | Urban Buses                  | Age, Fuel                                    |

### Emissions from road vehicle tire, brake, and surface wear

`gtfs2emis` also provides emissions estimates from tire, brake and
surface wear using the [EMEP/EEA
model](https://www.eea.europa.eu/en/analysis/publications/emep-eea-guidebook-2019).
The function estimates emissions of particulate matter (PM),
encompassing black carbon (BC), which arises from distinct sources
(tire, brake, and road surface wear). The focus is on primary particles,
which refer to those that are directly emitted, rather than those
generated from the re-suspension of previously deposited material.

## Learn more

Check out the guides for learning everything there is to know about all
the different features:

-   [Getting
    started](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_intro_vignette.html)
-   [Defining Fleet
    data](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_fleet_data.html)
-   [Exploring Emission
    Factors](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_emission_factor.html)
-   [Exploring Non Exhaust Emission
    Factors](https://ipeagit.github.io/gtfs2emis/articles/gtfs2emis_non_exhaust_ef.html)

### **Related packages**

There are several others transport emissions models available for
different purposes (see below). As of today, `gtfs2emis` is the only
method with the capability to estimate emissions of public transport
systems using GTFS data.

-   R: [vein](https://github.com/atmoschem/vein) Bottom-up and top-down
    inventory using GPS data.
-   R: [EmissV](https://github.com/atmoschem/emissv) Top-down inventory.
-   Python:
    [PythonEmissData](https://github.com/adelgadop/PythonEmissData)
    Jupyter notebook to estimate simple top-down emissions.
-   Python: [YETI](https://github.com/twollnik/YETI) YETI - Yet Another
    Emissions From Traffic Inventory
-   Python: [mobair](https://github.com/matteoboh/mobility_emissions)
    bottom-up model using GPS data.

### **Future enhancements**

-   Include cold-start, resuspension, and evaporative emissions factors
-   Add railway emission factors

------------------------------------------------------------------------

## Citation

``` r
citation("gtfs2emis")
#> To cite gtfs2emis in publications use:
#> 
#>   Vieira, J. P. B., Pereira, R. H. M., & Andrade, P. R. (2023). Estimating 
#>      Public Transport Emissions from General Transit Feed Specification Data. 
#>      Transportation Research Part D: Transport and Environment. Volume 119, 
#>      103757. https://doi.org/10.1016/j.trd.2023.103757
#> 
#> A BibTeX entry for LaTeX users is
#>   
#>   @article{vieira2023estimating,
#>     title = {Estimating Public Transport Emissions from {{General Transit Feed Specification}} Data},
#>     author = {Vieira, Jo{\~a}o Pedro Bazzo and Pereira, Rafael H. M. and Andrade, Pedro R.},
#>     year = {2023},
#>     month = jun,
#>     journal = {Transportation Research Part D: Transport and Environment},
#>     volume = {119},
#>     pages = {103757},
#>     issn = {1361-9209},
#>     doi = {10.1016/j.trd.2023.103757},
#>     urldate = {2023-05-06},
#>     langid = {english},
#>     keywords = {Emission factors,Emission models,GTFS,Gtfs2emis,Public transport emissions,Urban bus}
#>   }
```

### Credits <img src="man/figures/ipea_logo.png" alt="ipea" align="right" width="300"/>

The **gtfs2emis** package is developed by a team at the Institute for
Applied Economic Research (IPEA) in collaboration from the National
Institute for Space Research (INPE), both from Brazil.
