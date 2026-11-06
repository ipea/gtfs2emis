# Speed-dependent emission factor from the European Environment Agency (EMEP/EEA) model

Returns a list or data.table of emission factors for buses based on
EMEP/EEA air pollutant emission inventory guidebooks. The function uses
four emission factor databases published by EMEP/EEA, considering the
editions of 2019, 2016, 2013 and 2007. Estimates are expressed in units
'g/km'. See more in @details.

## Usage

``` r
ef_europe_emep(
  speed,
  veh_type,
  euro,
  pollutant,
  fuel = "D",
  tech = "SCR",
  slope = 0,
  load = 0.5,
  fcorr = 1,
  as_list = TRUE
)
```

## Arguments

- speed:

  units; Speed in 'km/h'.

- veh_type:

  character; Bus type, classified in "Ubus Midi \<=15 t","Ubus Std 15 -
  18 t","Ubus Artic \>18 t", "Coaches Std \<=18 t","Coaches Artic \>18
  t".

- euro:

  character; Euro period of vehicle, classified in "Conventional", "I",
  "II", "III", "IV", "V", "VI", and "EEV".

- pollutant:

  character; Pollutant, classified in
  "FC","CO2","CO","NOx","VOC","PM10","EC","CH4","NH3","N2O". "FC" is
  fuel consumption (g/km). "EC" is energy consumption in MJ/km, although
  it is returned with g/km units. FC and CO2 are not available for every
  combination (e.g. there is no CO2 for "BD" or for "Conventional"
  diesel buses).

- fuel:

  character; Fuel type, classified in "D" (Diesel),"DHD" (Diesel Hybrid
  ~ Diesel), "DHE" (Diesel Hybrid ~ Electricity), "CNG" (Compressed
  Natural Gas), "BD" (Biodiesel).

- tech:

  character; After treatment technology, classified in "SCR" (Selective
  Catalytic Reduction), "EGR" (Exhaust Gas Recirculation), and "DPF+SCR"
  (Diesel Particulate Filter + SCR, for Euro VI). Default is "SCR" for
  "IV" and "V". There are no available after treatment technology
  associated with euro standards "Conventional", "I", "II" and "III".

- slope:

  numeric; Slope gradient, classified in -0.06, -0.04, -0.02, 0.00,
  0.02, 0.04 and 0.06. Negative gradients means downhills and positive
  uphills. Default is 0.0. Either one value or one value per `speed`.
  Values are rounded to two decimals; other values are an error. Some
  pollutants (e.g. "CH4", "NH3", "N2O") and some CNG and hybrid
  combinations are only available at slope 0.00 and load 0.5; for them,
  that value is used with a message.

- load:

  numeric; Load ratio, classified in 0.0, 0.5 and 1.0. Default is 0.5.
  Either one value or one value per `speed`.

- fcorr:

  numeric; Correction based on fuel composition. The length must be one
  per each euro standards. Default is 1.0.

- as_list:

  logical; Returns emission factors as a list, instead of data.table
  format. Default is TRUE.

## Value

List. emission factors in units 'g/km' (list or a data.table).

## Details

The new convention for vehicles names are translated from the EMEP/EEA
report:

|  |  |
|----|----|
| vehicle category | description |
| Ubus Midi \<=15 t | Urban Bus Midi size, Gross Vehicle Weight (GVW) \<= 15 tons |
| Ubus Std 15 - 18 t | Urban Bus Standard size, GVW between 15 - 18 tons |
| Ubus Artic \>18 t | Urban Bus Articulated size, GVW \>= 18 tons |
| Coaches Std \<=18 t | Coach (inter-state) Standard size, GVW \<= 18 tons |
| Coaches Artic \>18 t | Coach (inter-state) Articulated size, GVW \> 18 tons |

When the information of vehicle technology does not match the existing
database, the function display a message mentioning the returned
technology. User can either select an existing data for the combining
variables (`euro`, `tech`, `veh_type` and `pollutant`), or accept the
assumed change in vehicle technology.

In order to cover more pollutants, vehicle technologies, and fuel
consumption data, the function uses four emission factor databases
published by EMEP/EEA, considering the editions of 2019, 2016, 2013 and
2007.

The R scripts used to download and pre-process 4 EMEP/EEA editions
(2019, 2016, 2013 and 2007) can be accessed in the 'gtfs2emis' GitHub
repository at
\<<https://github.com/ipeaGIT/gtfs2emis/blob/master/data-raw/ef_europe_emep_db.R>\>

EMEP/EEA data and reports can be accessed in the following links:

- 2019 edition
  <https://www.eea.europa.eu/en/analysis/publications/emep-eea-guidebook-2019/part-b-sectoral-guidance-chapters/1-energy/>,

- 2016 edition
  <https://www.eea.europa.eu/publications/emep-eea-guidebook-2016/>,

- 2013 edition
  <https://www.eea.europa.eu/publications/emep-eea-guidebook-2013/>, and

- 2007 edition <https://www.eea.europa.eu/publications/EMEPCORINAIR5/>.

## See also

Other Emission factor model:
[`ef_brazil_cetesb()`](https://ipeagit.github.io/gtfs2emis/dev/reference/ef_brazil_cetesb.md),
[`ef_scaled_euro()`](https://ipeagit.github.io/gtfs2emis/dev/reference/ef_scaled_euro.md),
[`ef_usa_emfac()`](https://ipeagit.github.io/gtfs2emis/dev/reference/ef_usa_emfac.md),
[`ef_usa_moves()`](https://ipeagit.github.io/gtfs2emis/dev/reference/ef_usa_moves.md),
[`emi_europe_emep_wear()`](https://ipeagit.github.io/gtfs2emis/dev/reference/emi_europe_emep_wear.md)

## Examples

``` r
ef_europe_emep( speed = units::set_units(1:100,"km/h"),
                veh_type = c("Ubus Midi <=15 t","Ubus Std 15 - 18 t","Ubus Artic >18 t"),
                euro = c("IV","V"),
                fuel = "D",
                pollutant = c("CO","PM10","CH4","NOx"),
                as_list = FALSE) 
#>            CO_Euro_IV        CO_Euro_V      PM10_Euro_IV       PM10_Euro_V
#>               <units>          <units>           <units>           <units>
#>   1: 1.7887769 [g/km] 10.207133 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>   2: 1.7887769 [g/km] 10.207133 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>   3: 1.7887769 [g/km] 10.207133 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>   4: 1.7887769 [g/km] 10.207133 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>   5: 1.7887769 [g/km] 10.207133 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>   6: 1.7887769 [g/km]  8.960425 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>   7: 1.7887769 [g/km]  7.872159 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>   8: 1.7887769 [g/km]  6.971286 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>   9: 1.7887769 [g/km]  6.236581 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>  10: 1.7887769 [g/km]  5.635924 [g/km] 0.05678656 [g/km] 0.10527752 [g/km]
#>  11: 1.7887769 [g/km]  5.140274 [g/km] 0.05678656 [g/km] 0.09857818 [g/km]
#>  12: 1.6646041 [g/km]  4.726557 [g/km] 0.05389617 [g/km] 0.09278112 [g/km]
#>  13: 1.5586009 [g/km]  4.377183 [g/km] 0.05137958 [g/km] 0.08772752 [g/km]
#>  14: 1.4669606 [g/km]  4.078870 [g/km] 0.04916423 [g/km] 0.08329011 [g/km]
#>  15: 1.3868797 [g/km]  3.821557 [g/km] 0.04719595 [g/km] 0.07936711 [g/km]
#>  16: 1.3162466 [g/km]  3.597558 [g/km] 0.04543344 [g/km] 0.07587681 [g/km]
#>  17: 1.2534396 [g/km]  3.400935 [g/km] 0.04384455 [g/km] 0.07275328 [g/km]
#>  18: 1.1971916 [g/km]  3.227046 [g/km] 0.04240378 [g/km] 0.06994287 [g/km]
#>  19: 1.1464982 [g/km]  3.072222 [g/km] 0.04109068 [g/km] 0.06740165 [g/km]
#>  20: 1.1005520 [g/km]  2.933529 [g/km] 0.03988854 [g/km] 0.06509335 [g/km]
#>  21: 1.0586969 [g/km]  2.808598 [g/km] 0.03878362 [g/km] 0.06298782 [g/km]
#>  22: 1.0203936 [g/km]  2.695496 [g/km] 0.03776446 [g/km] 0.06105981 [g/km]
#>  23: 0.9851947 [g/km]  2.592632 [g/km] 0.03682142 [g/km] 0.05928802 [g/km]
#>  24: 0.9527259 [g/km]  2.498687 [g/km] 0.03594632 [g/km] 0.05765441 [g/km]
#>  25: 0.9226713 [g/km]  2.412555 [g/km] 0.03513218 [g/km] 0.05614356 [g/km]
#>  26: 0.8947627 [g/km]  2.333306 [g/km] 0.03437298 [g/km] 0.05474225 [g/km]
#>  27: 0.8687706 [g/km]  2.260151 [g/km] 0.03366352 [g/km] 0.05343908 [g/km]
#>  28: 0.8444975 [g/km]  2.192416 [g/km] 0.03299925 [g/km] 0.05222416 [g/km]
#>  29: 0.8217727 [g/km]  2.129522 [g/km] 0.03237621 [g/km] 0.05108887 [g/km]
#>  30: 0.8004474 [g/km]  2.070971 [g/km] 0.03179088 [g/km] 0.05002568 [g/km]
#>  31: 0.7803917 [g/km]  2.016328 [g/km] 0.03124018 [g/km] 0.04902797 [g/km]
#>  32: 0.7614914 [g/km]  1.965217 [g/km] 0.03072136 [g/km] 0.04808990 [g/km]
#>  33: 0.7436459 [g/km]  1.917307 [g/km] 0.03023197 [g/km] 0.04720630 [g/km]
#>  34: 0.7267660 [g/km]  1.872307 [g/km] 0.02976981 [g/km] 0.04637259 [g/km]
#>  35: 0.7107725 [g/km]  1.829959 [g/km] 0.02933291 [g/km] 0.04558467 [g/km]
#>  36: 0.6955948 [g/km]  1.790038 [g/km] 0.02891951 [g/km] 0.04483888 [g/km]
#>  37: 0.6811696 [g/km]  1.752340 [g/km] 0.02852800 [g/km] 0.04413195 [g/km]
#>  38: 0.6674401 [g/km]  1.716685 [g/km] 0.02815694 [g/km] 0.04346093 [g/km]
#>  39: 0.6543553 [g/km]  1.682911 [g/km] 0.02780499 [g/km] 0.04282315 [g/km]
#>  40: 0.6418690 [g/km]  1.650875 [g/km] 0.02747096 [g/km] 0.04221621 [g/km]
#>  41: 0.6299394 [g/km]  1.620445 [g/km] 0.02715376 [g/km] 0.04163794 [g/km]
#>  42: 0.6185286 [g/km]  1.591504 [g/km] 0.02685239 [g/km] 0.04108635 [g/km]
#>  43: 0.6076021 [g/km]  1.563944 [g/km] 0.02656592 [g/km] 0.04055965 [g/km]
#>  44: 0.5971284 [g/km]  1.537671 [g/km] 0.02629351 [g/km] 0.04005620 [g/km]
#>  45: 0.5870789 [g/km]  1.512595 [g/km] 0.02603438 [g/km] 0.03957448 [g/km]
#>  46: 0.5774271 [g/km]  1.488637 [g/km] 0.02578783 [g/km] 0.03911313 [g/km]
#>  47: 0.5681490 [g/km]  1.465723 [g/km] 0.02555318 [g/km] 0.03867088 [g/km]
#>  48: 0.5592224 [g/km]  1.443788 [g/km] 0.02532983 [g/km] 0.03824657 [g/km]
#>  49: 0.5506267 [g/km]  1.422769 [g/km] 0.02511721 [g/km] 0.03783914 [g/km]
#>  50: 0.5423432 [g/km]  1.402611 [g/km] 0.02491479 [g/km] 0.03744760 [g/km]
#>  51: 0.5343545 [g/km]  1.383262 [g/km] 0.02472209 [g/km] 0.03707104 [g/km]
#>  52: 0.5266443 [g/km]  1.364673 [g/km] 0.02453866 [g/km] 0.03670862 [g/km]
#>  53: 0.5191977 [g/km]  1.346802 [g/km] 0.02436407 [g/km] 0.03635955 [g/km]
#>  54: 0.5120010 [g/km]  1.329607 [g/km] 0.02419793 [g/km] 0.03602312 [g/km]
#>  55: 0.5050410 [g/km]  1.313050 [g/km] 0.02403987 [g/km] 0.03569864 [g/km]
#>  56: 0.4983059 [g/km]  1.297098 [g/km] 0.02388954 [g/km] 0.03538551 [g/km]
#>  57: 0.4917845 [g/km]  1.281716 [g/km] 0.02374663 [g/km] 0.03508312 [g/km]
#>  58: 0.4854662 [g/km]  1.266877 [g/km] 0.02361083 [g/km] 0.03479094 [g/km]
#>  59: 0.4793413 [g/km]  1.252550 [g/km] 0.02348187 [g/km] 0.03450847 [g/km]
#>  60: 0.4734007 [g/km]  1.238710 [g/km] 0.02335948 [g/km] 0.03423522 [g/km]
#>  61: 0.4676358 [g/km]  1.225333 [g/km] 0.02324340 [g/km] 0.03397075 [g/km]
#>  62: 0.4620386 [g/km]  1.212395 [g/km] 0.02313341 [g/km] 0.03371464 [g/km]
#>  63: 0.4566016 [g/km]  1.199877 [g/km] 0.02302929 [g/km] 0.03346651 [g/km]
#>  64: 0.4513176 [g/km]  1.187756 [g/km] 0.02293084 [g/km] 0.03322599 [g/km]
#>  65: 0.4461800 [g/km]  1.176016 [g/km] 0.02283785 [g/km] 0.03299274 [g/km]
#>  66: 0.4411825 [g/km]  1.164637 [g/km] 0.02275014 [g/km] 0.03276642 [g/km]
#>  67: 0.4363193 [g/km]  1.153605 [g/km] 0.02266755 [g/km] 0.03254675 [g/km]
#>  68: 0.4315847 [g/km]  1.142902 [g/km] 0.02258990 [g/km] 0.03233341 [g/km]
#>  69: 0.4269735 [g/km]  1.132515 [g/km] 0.02251706 [g/km] 0.03212616 [g/km]
#>  70: 0.4224807 [g/km]  1.122430 [g/km] 0.02244887 [g/km] 0.03192473 [g/km]
#>  71: 0.4181015 [g/km]  1.112634 [g/km] 0.02238519 [g/km] 0.03172888 [g/km]
#>  72: 0.4138316 [g/km]  1.103115 [g/km] 0.02232590 [g/km] 0.03153838 [g/km]
#>  73: 0.4096668 [g/km]  1.093860 [g/km] 0.02227087 [g/km] 0.03135301 [g/km]
#>  74: 0.4056029 [g/km]  1.084860 [g/km] 0.02222000 [g/km] 0.03117257 [g/km]
#>  75: 0.4016363 [g/km]  1.076104 [g/km] 0.02217317 [g/km] 0.03099688 [g/km]
#>  76: 0.3977633 [g/km]  1.067582 [g/km] 0.02213027 [g/km] 0.03082573 [g/km]
#>  77: 0.3939805 [g/km]  1.059284 [g/km] 0.02209122 [g/km] 0.03065896 [g/km]
#>  78: 0.3902846 [g/km]  1.051203 [g/km] 0.02205592 [g/km] 0.03049640 [g/km]
#>  79: 0.3866726 [g/km]  1.043329 [g/km] 0.02202427 [g/km] 0.03033790 [g/km]
#>  80: 0.3831415 [g/km]  1.035655 [g/km] 0.02199621 [g/km] 0.03018331 [g/km]
#>  81: 0.3796884 [g/km]  1.028174 [g/km] 0.02197166 [g/km] 0.03003247 [g/km]
#>  82: 0.3763108 [g/km]  1.020877 [g/km] 0.02195053 [g/km] 0.02988526 [g/km]
#>  83: 0.3730061 [g/km]  1.013759 [g/km] 0.02193276 [g/km] 0.02974156 [g/km]
#>  84: 0.3697718 [g/km]  1.006813 [g/km] 0.02191829 [g/km] 0.02960122 [g/km]
#>  85: 0.3666055 [g/km]  1.000033 [g/km] 0.02190705 [g/km] 0.02946414 [g/km]
#>  86: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  87: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  88: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  89: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  90: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  91: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  92: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  93: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  94: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  95: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  96: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  97: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  98: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>  99: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#> 100: 0.3635052 [g/km]  1.000033 [g/km] 0.02189898 [g/km] 0.02946414 [g/km]
#>            CO_Euro_IV        CO_Euro_V      PM10_Euro_IV       PM10_Euro_V
#>               <units>          <units>           <units>           <units>
#>         CH4_Euro_IV     CH4_Euro_V     NOx_Euro_IV       NOx_Euro_V
#>             <units>        <units>         <units>          <units>
#>   1: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 24.351882 [g/km]
#>   2: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 24.351882 [g/km]
#>   3: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 24.351882 [g/km]
#>   4: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 24.351882 [g/km]
#>   5: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 24.351882 [g/km]
#>   6: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 21.626354 [g/km]
#>   7: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 19.534300 [g/km]
#>   8: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 17.853729 [g/km]
#>   9: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 16.459202 [g/km]
#>  10: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 15.273909 [g/km]
#>  11: 0.00525 [g/km] 0.00525 [g/km] 7.371010 [g/km] 14.247814 [g/km]
#>  12: 0.00525 [g/km] 0.00525 [g/km] 6.937083 [g/km] 13.346684 [g/km]
#>  13: 0.00525 [g/km] 0.00525 [g/km] 6.581100 [g/km] 12.546143 [g/km]
#>  14: 0.00525 [g/km] 0.00525 [g/km] 6.279923 [g/km] 11.828254 [g/km]
#>  15: 0.00525 [g/km] 0.00525 [g/km] 6.019700 [g/km] 11.179450 [g/km]
#>  16: 0.00525 [g/km] 0.00525 [g/km] 5.791331 [g/km] 10.589227 [g/km]
#>  17: 0.00525 [g/km] 0.00525 [g/km] 5.588457 [g/km] 10.049287 [g/km]
#>  18: 0.00525 [g/km] 0.00525 [g/km] 5.406438 [g/km]  9.552964 [g/km]
#>  19: 0.00525 [g/km] 0.00525 [g/km] 5.241775 [g/km]  9.094821 [g/km]
#>  20: 0.00525 [g/km] 0.00525 [g/km] 5.091762 [g/km]  8.670366 [g/km]
#>  21: 0.00525 [g/km] 0.00525 [g/km] 4.954263 [g/km]  8.275843 [g/km]
#>  22: 0.00525 [g/km] 0.00525 [g/km] 4.827565 [g/km]  7.908083 [g/km]
#>  23: 0.00525 [g/km] 0.00525 [g/km] 4.710272 [g/km]  7.564386 [g/km]
#>  24: 0.00525 [g/km] 0.00525 [g/km] 4.601233 [g/km]  7.242433 [g/km]
#>  25: 0.00525 [g/km] 0.00525 [g/km] 4.499489 [g/km]  6.940219 [g/km]
#>  26: 0.00525 [g/km] 0.00525 [g/km] 4.404234 [g/km]  6.655999 [g/km]
#>  27: 0.00525 [g/km] 0.00525 [g/km] 4.314784 [g/km]  6.388243 [g/km]
#>  28: 0.00525 [g/km] 0.00525 [g/km] 4.230551 [g/km]  6.135608 [g/km]
#>  29: 0.00525 [g/km] 0.00525 [g/km] 4.151033 [g/km]  5.896902 [g/km]
#>  30: 0.00525 [g/km] 0.00525 [g/km] 4.075793 [g/km]  5.671069 [g/km]
#>  31: 0.00525 [g/km] 0.00525 [g/km] 4.004448 [g/km]  5.457166 [g/km]
#>  32: 0.00525 [g/km] 0.00525 [g/km] 3.936665 [g/km]  5.254351 [g/km]
#>  33: 0.00525 [g/km] 0.00525 [g/km] 3.872151 [g/km]  5.061864 [g/km]
#>  34: 0.00525 [g/km] 0.00525 [g/km] 3.810643 [g/km]  4.879025 [g/km]
#>  35: 0.00525 [g/km] 0.00525 [g/km] 3.751910 [g/km]  4.705215 [g/km]
#>  36: 0.00525 [g/km] 0.00525 [g/km] 3.695746 [g/km]  4.539877 [g/km]
#>  37: 0.00525 [g/km] 0.00525 [g/km] 3.641965 [g/km]  4.382505 [g/km]
#>  38: 0.00525 [g/km] 0.00525 [g/km] 3.590401 [g/km]  4.232637 [g/km]
#>  39: 0.00525 [g/km] 0.00525 [g/km] 3.540904 [g/km]  4.089853 [g/km]
#>  40: 0.00525 [g/km] 0.00525 [g/km] 3.493336 [g/km]  3.953770 [g/km]
#>  41: 0.00525 [g/km] 0.00525 [g/km] 3.447575 [g/km]  3.824038 [g/km]
#>  42: 0.00525 [g/km] 0.00525 [g/km] 3.403508 [g/km]  3.700336 [g/km]
#>  43: 0.00525 [g/km] 0.00525 [g/km] 3.361033 [g/km]  3.582371 [g/km]
#>  44: 0.00525 [g/km] 0.00525 [g/km] 3.320055 [g/km]  3.469872 [g/km]
#>  45: 0.00525 [g/km] 0.00525 [g/km] 3.280489 [g/km]  3.362594 [g/km]
#>  46: 0.00525 [g/km] 0.00525 [g/km] 3.242255 [g/km]  3.260308 [g/km]
#>  47: 0.00525 [g/km] 0.00525 [g/km] 3.205280 [g/km]  3.162809 [g/km]
#>  48: 0.00525 [g/km] 0.00525 [g/km] 3.169497 [g/km]  3.069903 [g/km]
#>  49: 0.00525 [g/km] 0.00525 [g/km] 3.134844 [g/km]  2.981417 [g/km]
#>  50: 0.00525 [g/km] 0.00525 [g/km] 3.101263 [g/km]  2.897189 [g/km]
#>  51: 0.00525 [g/km] 0.00525 [g/km] 3.068700 [g/km]  2.817074 [g/km]
#>  52: 0.00525 [g/km] 0.00525 [g/km] 3.037106 [g/km]  2.740938 [g/km]
#>  53: 0.00525 [g/km] 0.00525 [g/km] 3.006433 [g/km]  2.668657 [g/km]
#>  54: 0.00525 [g/km] 0.00525 [g/km] 2.976640 [g/km]  2.600122 [g/km]
#>  55: 0.00525 [g/km] 0.00525 [g/km] 2.947685 [g/km]  2.535233 [g/km]
#>  56: 0.00525 [g/km] 0.00525 [g/km] 2.919530 [g/km]  2.473899 [g/km]
#>  57: 0.00525 [g/km] 0.00525 [g/km] 2.892140 [g/km]  2.416041 [g/km]
#>  58: 0.00525 [g/km] 0.00525 [g/km] 2.865482 [g/km]  2.361587 [g/km]
#>  59: 0.00525 [g/km] 0.00525 [g/km] 2.839525 [g/km]  2.310475 [g/km]
#>  60: 0.00525 [g/km] 0.00525 [g/km] 2.814239 [g/km]  2.262653 [g/km]
#>  61: 0.00525 [g/km] 0.00525 [g/km] 2.789596 [g/km]  2.218074 [g/km]
#>  62: 0.00525 [g/km] 0.00525 [g/km] 2.765571 [g/km]  2.176704 [g/km]
#>  63: 0.00525 [g/km] 0.00525 [g/km] 2.742139 [g/km]  2.138514 [g/km]
#>  64: 0.00525 [g/km] 0.00525 [g/km] 2.719276 [g/km]  2.103483 [g/km]
#>  65: 0.00525 [g/km] 0.00525 [g/km] 2.696961 [g/km]  2.071601 [g/km]
#>  66: 0.00525 [g/km] 0.00525 [g/km] 2.675174 [g/km]  2.042864 [g/km]
#>  67: 0.00525 [g/km] 0.00525 [g/km] 2.653893 [g/km]  2.017277 [g/km]
#>  68: 0.00525 [g/km] 0.00525 [g/km] 2.633101 [g/km]  1.994856 [g/km]
#>  69: 0.00525 [g/km] 0.00525 [g/km] 2.612780 [g/km]  1.975622 [g/km]
#>  70: 0.00525 [g/km] 0.00525 [g/km] 2.592913 [g/km]  1.959608 [g/km]
#>  71: 0.00525 [g/km] 0.00525 [g/km] 2.573485 [g/km]  1.946858 [g/km]
#>  72: 0.00525 [g/km] 0.00525 [g/km] 2.554479 [g/km]  1.937423 [g/km]
#>  73: 0.00525 [g/km] 0.00525 [g/km] 2.535882 [g/km]  1.931367 [g/km]
#>  74: 0.00525 [g/km] 0.00525 [g/km] 2.517680 [g/km]  1.928766 [g/km]
#>  75: 0.00525 [g/km] 0.00525 [g/km] 2.499859 [g/km]  1.929707 [g/km]
#>  76: 0.00525 [g/km] 0.00525 [g/km] 2.482407 [g/km]  1.934291 [g/km]
#>  77: 0.00525 [g/km] 0.00525 [g/km] 2.465313 [g/km]  1.942636 [g/km]
#>  78: 0.00525 [g/km] 0.00525 [g/km] 2.448564 [g/km]  1.954871 [g/km]
#>  79: 0.00525 [g/km] 0.00525 [g/km] 2.432150 [g/km]  1.971148 [g/km]
#>  80: 0.00525 [g/km] 0.00525 [g/km] 2.416060 [g/km]  1.991633 [g/km]
#>  81: 0.00525 [g/km] 0.00525 [g/km] 2.400285 [g/km]  2.016517 [g/km]
#>  82: 0.00525 [g/km] 0.00525 [g/km] 2.384815 [g/km]  2.046013 [g/km]
#>  83: 0.00525 [g/km] 0.00525 [g/km] 2.369640 [g/km]  2.080360 [g/km]
#>  84: 0.00525 [g/km] 0.00525 [g/km] 2.354752 [g/km]  2.119827 [g/km]
#>  85: 0.00525 [g/km] 0.00525 [g/km] 2.340142 [g/km]  2.164714 [g/km]
#>  86: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  87: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  88: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  89: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  90: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  91: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  92: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  93: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  94: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  95: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  96: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  97: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  98: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>  99: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#> 100: 0.00525 [g/km] 0.00525 [g/km] 2.325803 [g/km]  2.164714 [g/km]
#>         CH4_Euro_IV     CH4_Euro_V     NOx_Euro_IV       NOx_Euro_V
#>             <units>        <units>         <units>          <units>
```
