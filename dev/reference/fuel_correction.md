# Correction factor equation

Relations between emissions and fuel properties for diesel heavy-duty
vehicles based on EMEP/EEA. Function based on values from the [EMEP/EEA
air pollutant emission inventory guidebook
2019](https://www.eea.europa.eu/en/analysis/publications/emep-eea-guidebook-2019).
Estimates are given by the ratio between correction factor of improved
fuel by the correction factor of base fuel.

## Usage

``` r
fuel_correction(
  pollutant,
  euro_stage,
  improved_fuel = c(den = 835, s = 40, pah = 5, cn = 53, t95 = 320)
)
```

## Arguments

- pollutant:

  character. Pollutant classified in "CO", "VOC", "NOx" or "PM10".

- euro_stage:

  character. EURO period of vehicle, classified in "PRE", "I", "II",
  "III", "IV", "V" and "VI".

- improved_fuel:

  numeric. Numeric vector for characteristics of an improved fuel,
  ordered by: den (Density at 15 degrees C), s (Sulphur content in ppm),
  pah (Polycyclic aromatics content in \\ number), t95 (Back end
  distillation in degrees C). Default input uses c(den = 835, s = 40,
  pah = 5, cn = 53, t95 = 320).

## Value

numeric. A fuel correction factor.
