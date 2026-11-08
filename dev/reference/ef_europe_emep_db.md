# Emission factors from European Environment Agency — EMEP/EEA

Hot exhaust emission factors are speed dependent functions and are
expressed in g/km. It varies by fuel, vehicle segment, euro standard,
pollutant, and after treatment technology. These variables are
consolidated in different EF equations, given by:

## Usage

``` r
ef_europe_emep_db
```

## Format

A data.table with 9388 rows and 22 variables:

- Category:

  Buses.

- Fuel:

  Fuel type, classified in "D" (Diesel),"DHD" (Diesel Hybrid ~ Diesel),
  "DHE" (Diesel Hybrid ~ Electricity), "CNG" (Compressed Natural Gas),
  "BD" (Biodiesel).

- Segment:

  character; Bus type, classified in "Ubus Midi \<=15 t","Ubus Std 15 -
  18 t","Ubus Artic \>18 t", "Coaches Std \<=18 t","Coaches Artic \>18
  t".

- Euro:

  character; Euro period of vehicle, classified in "Conventional", "I",
  "II", "III", "IV", "V", "VI", and "EEV".

- Technology:

  character; After treatment technology, classified in "SCR" (Selective
  Catalytic Reduction), "EGR" (Exhaust Gas Recirculation), and "DPF+SCR"
  (Diesel Particulate Filter + SCR, for Euro VI). Default is "SCR" for
  "IV" and "V". There are no available after treatment technology
  associated with euro standards "Conventional", "I", "II" and "III".

- Pol:

  character; Pollutant, classified in
  "FC","CO2","CO","NOx","VOC","PM10","EC","CH4","NH3","N2O". "FC" is
  fuel consumption (g/km); "EC" is energy consumption (MJ/km).

- Vmin:

  Minimum speed for emission factor estimation, in km/h.

- Vmax:

  Maximum speed for emission factor estimation, in km/h.

- Alpha, Beta, Gamma, Delta, Epsilon, Zita, Hta, Thita:

  Constant parameters.

- RF:

  Reduction Factor; In percentage (%) units.

- k:

  Constant factor.

## Source

More information can be found at
<https://www.eea.europa.eu//publications/emep-eea-guidebook-2019>,
<https://www.eea.europa.eu/publications/emep-eea-guidebook-2016/>,
<https://www.eea.europa.eu/publications/emep-eea-guidebook-2013/>, and
<https://www.eea.europa.eu/publications/EMEPCORINAIR5/>.

## Details

EF = EF(Alpha, Beta, Gamma, Delta, Epsilon, Zita, Hta, RF, Speed,
Function_ID, k, fcorr),

where Alpha, Beta, Gamma, Delta, Epsilon, Zeta, Eta are constant
parameters; RF is the Reduction Factor, Speed in the average speed,
Function_ID is the equation (function of on the year of the inventory
and the pollutant); k is a constant value, and fcorr is the fuel
correction factor.

The emissions factors are derived from the EMEP/EEA air pollutant
emission inventory guidebook (formerly called the EMEP CORINAIR emission
inventory guidebook). The document provides guidance on estimating
emissions from both anthropogenic and natural emission sources.

The package presents a combination of emission factors from EMEP/EEA
guidelines of 2007, 2013, 2016, and 2019, aiming to cover a greater
number of pollutants and vehicle segments. The script used to process
the raw EMEP/EEA databases can be found in the repository
\<<https://github.com/ipea/gtfs2emis/blob/master/data-raw/ef_europe_emep_db.R>\>.

## See also

Other emission factor data:
[`ef_brazil_cetesb_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_brazil_cetesb_db.md),
[`ef_usa_emfac_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_emfac_db.md),
[`ef_usa_moves_db`](https://ipea.github.io/gtfs2emis/dev/reference/ef_usa_moves_db.md)
