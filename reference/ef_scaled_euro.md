# Scale local emission factors in order to make emission estimates a function of speed.

Scale emission factors to account for vehicle speed based on values from
the emission factor model by the European Environment Agency (EMEP/EEA).
Emission factor estimates are expressed in units 'g/km'.

## Usage

``` r
ef_scaled_euro(
  ef_local,
  speed,
  veh_type,
  euro,
  pollutant,
  fuel = "D",
  tech = "SCR",
  SDC = 19,
  slope = 0,
  load = 0.5,
  fcorr = 1
)
```

## Arguments

- ef_local:

  data.frame or a list containing the emission factors data.frame. Local
  emission factors, in units 'g/km'.

- speed:

  units. Speed in 'km/h'.

- veh_type:

  character. Bus type, classified as "Ubus Midi \<=15 t", "Ubus Std 15 -
  18 t", "Ubus Artic \>18 t", "Coaches Std \<=18 t", or "Coaches Artic
  \>18 t".

- euro:

  character. Euro period of vehicle, classified in "Conventional", "I",
  "II", "III", "IV", "V", "VI", and "EEV".

- pollutant:

  character. Pollutant: "FC", "CO2", "CO", "NOx", "VOC", "PM10", "EC",
  "CH4", "NH3", "N2O", "FC" (fuel consumption).

- fuel:

  character. Fuel type, classified in "D" (Diesel), "DHD" (Diesel Hybrid
  ~ Diesel), "DHE" (Diesel Hybrid ~ Electricity), "CNG" (Compressed
  Natural Gas), "BD" (Biodiesel). Default is "D".

- tech:

  character. After treatment technology, classified in "SCR" (Selective
  Catalytic Reduction), "EGR" (Exhaust Gas Recirculation), and "DPF+SCR"
  (Diesel Particulate Filter + SCR, for Euro VI). Default is "SCR" for
  "IV" and "V".

- SDC:

  numeric. Average speed of urban driving condition in 'km/h'. Default
  is 19 km/h, which is the average speed adopted in EMEP/EEA report.

- slope:

  numeric. Slope gradient, categorized in -0.06, -0.04, -0.02, 0.00,
  0.02, 0.04 and 0.06. Negative gradients means downhills and positive
  uphills. Default is 0.0.

- load:

  numeric. Passenger load ratio, classified in 0.0, 0.5 and 1.0. Default
  is 0.5.

- fcorr:

  numeric. Correction based on fuel composition. The length must be one
  per each euro standards. Default is 1.0.

## Value

list. Emission factors in units 'g/km'.

## Details

The scaled emission factor is related to speed by the expression

EF_scaled (V) = EF_local \* ( EF(V) / EF(SDC)),

where EF_scaled(V) is the scaled emission factors for each street link,
EF_local is the local emission factor, EF(V) and EF(SDC) are the
EMEP/EEA emission factor the speed of V and the average urban driving
speed 'SDC', respectively.

Please note that the function reads the vector arguments in the same
order as informed by the user. For instance, if the pollutant input is
`c("CO","PM10")` input in the local emission factor function, the order
needs to be the same for the pollutant in the `ef_scaled_euro` function.

In the case of vehicle type, which generally changes according to the
emission factor source, the input argument in the `ef_scaled_euro` needs
to be consistent with the order adopted in the local emission factor
function.

For example, if the vector of local vehicle type is
`c("BUS_URBAN_D","BUS_MICRO_D")`, the related vector for EMEP/EEA model
needs to be `c("Ubus Std 15 - 18 t","Ubus Midi <=15 t")`. The same
approach applies for other input arguments. See more in the examples.

## See also

Other Emission factor model:
[`ef_brazil_cetesb()`](https://ipeagit.github.io/gtfs2emis/reference/ef_brazil_cetesb.md),
[`ef_europe_emep()`](https://ipeagit.github.io/gtfs2emis/reference/ef_europe_emep.md),
[`ef_usa_emfac()`](https://ipeagit.github.io/gtfs2emis/reference/ef_usa_emfac.md),
[`ef_usa_moves()`](https://ipeagit.github.io/gtfs2emis/reference/ef_usa_moves.md),
[`emi_europe_emep_wear()`](https://ipeagit.github.io/gtfs2emis/reference/emi_europe_emep_wear.md)

## Examples

``` r
temp_ef_br <- ef_brazil_cetesb(
                    pollutant = c("CO","PM10","CO2","CH4","NOx"),
                    veh_type = c("BUS_URBAN_D","BUS_MICRO_D"),
                    model_year = c(2015,2015),
                    as_list = TRUE
                    )

temp_ef_scaled <- ef_scaled_euro(
                    ef_local = temp_ef_br,
                    speed = units::set_units(1:100,"km/h"),
                    veh_type = c("Ubus Std 15 - 18 t","Ubus Midi <=15 t"),
                    euro = c("IV","IV"),
                    fuel = c("D","D"),
                    tech = c("SCR","SCR"),
                    pollutant = c("CO","PM10","CO2","CH4","NOx")
                    )
#> "CO2" emission factor not found for technology "SCR" and Euro "IV".
#> ℹ The package assumes missing Technology entry. Check `data(ef_europe_emep_db)`
#>   for available data.
#> "CO2" emission factor not found for technology "SCR" and Euro "IV".
#> ℹ The package assumes missing Technology entry. Check `data(ef_europe_emep_db)`
#>   for available data.
#> "CO2" emission factor not found for technology "SCR" and Euro "IV".
#> ℹ The package assumes missing Technology entry. Check `data(ef_europe_emep_db)`
#>   for available data.
#> "CO2" emission factor not found for technology "SCR" and Euro "IV".
#> ℹ The package assumes missing Technology entry. Check `data(ef_europe_emep_db)`
#>   for available data.
```
