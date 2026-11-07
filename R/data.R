#' Emission factors from European Environment Agency — EMEP/EEA
#'
#' Hot exhaust emission factors are speed dependent functions and are expressed in g/km. 
#' It varies by fuel, vehicle segment, euro standard, pollutant, and after treatment technology. 
#' These variables are consolidated in different EF equations, given by:
#'
#' EF = EF(Alpha, Beta, Gamma, Delta, Epsilon, Zita, Hta, RF, Speed, Function_ID, k, fcorr),
#' 
#' where Alpha, Beta, Gamma, Delta, Epsilon, Zeta, Eta are constant parameters; 
#' RF is the Reduction Factor, Speed in the average speed, Function_ID is the 
#' equation (function of on the year of the inventory and the pollutant); k is 
#' a constant value, and fcorr is the fuel correction factor.
#' 
#' The emissions factors are derived from the EMEP/EEA air pollutant emission inventory guidebook
#' (formerly called the EMEP CORINAIR emission inventory guidebook). The document provides guidance on
#' estimating emissions from both anthropogenic and natural emission sources. 
#' 
#' The package presents a combination of emission factors from EMEP/EEA guidelines of 2007,
#'  2013, 2016, and 2019, aiming to cover a greater number of pollutants and vehicle segments.
#'  The script used to process the raw EMEP/EEA databases can be found in the repository
#'  <<https://github.com/ipea/gtfs2emis/blob/master/data-raw/ef_europe_emep_db.R>>.
#'  
#'  
#' @format A data.table with 9388 rows and 22 variables:
#' \describe{
#' \item{Category}{Buses.}
#' \item{Fuel}{Fuel type, classified in "D" (Diesel),"DHD" (Diesel Hybrid ~ Diesel),
#' "DHE" (Diesel Hybrid ~ Electricity), "CNG" (Compressed Natural Gas), "BD" (Biodiesel). }
#' \item{Segment}{character; Bus type, classified in "Ubus Midi <=15 t","Ubus Std 15 - 18 t","Ubus Artic >18 t",
#' "Coaches Std <=18 t","Coaches Artic >18 t".}
#' \item{Euro}{character; Euro period of vehicle, classified in "Conventional", "I", "II", "III", "IV", "V", "VI", and "EEV".}
#' \item{Technology}{character; After treatment technology, classified in "SCR" (Selective Catalytic Reduction), 
#' "EGR" (Exhaust Gas Recirculation), and "DPF+SCR" (Diesel Particulate Filter + SCR, for Euro VI). Default is "SCR" for "IV" and "V". There are 
#' no available after treatment technology associated with euro standards "Conventional", "I", "II" and "III". }
#' \item{Pol}{character; Pollutant, classified in "FC","CO2","CO","NOx","VOC","PM10","EC","CH4","NH3","N2O". "FC" is fuel consumption (g/km); "EC" is energy consumption (MJ/km). }
#' \item{Vmin}{Minimum speed for emission factor estimation, in km/h.}
#' \item{Vmax}{Maximum speed for emission factor estimation, in km/h.}
#' \item{Alpha, Beta, Gamma, Delta, Epsilon, Zita, Hta, Thita}{Constant parameters.}
#' \item{RF}{Reduction Factor; In percentage (%) units.}
#' \item{k}{Constant factor.}
#' }
#' @source More information can be found at 
#' \url{https://www.eea.europa.eu//publications/emep-eea-guidebook-2019},
#' \url{https://www.eea.europa.eu/publications/emep-eea-guidebook-2016/},
#' \url{https://www.eea.europa.eu/publications/emep-eea-guidebook-2013/}, and
#' \url{https://www.eea.europa.eu/publications/EMEPCORINAIR5/}.
#' @family emission factor data
"ef_europe_emep_db" # data(ef_europe_emep_db)


#' Emission factors from California Air Resources Board (EMFAC Model)
#' 
#' Running exhaust emissions factors from [EMFAC2017 model](https://arb.ca.gov/emfac/emissions-inventory).
#'  The model generates emission factors (EF) of urban buses in California (United States), considering 
#' different pollutants, years of reference, model year, fuel, speed ranges,
#' type of regions, model version, and type of season. Currently, the package 
#' supports EFs only for "Statewide" region type, and "Annual" season. 
#' Specific data of other regions and seasons can be download at <<https://arb.ca.gov/emfac/emissions-inventory>>.
#' 
#' The function returns the data in a data.frame format. The R script used to process 
#' the raw EMFAC database can be found in the repository
#' <<https://github.com/ipea/gtfs2emis/blob/master/data-raw/ef_usa_emfac_db.R>>.
#' 
#'
#' @format A data.table with 79198 rows and 8 variables:
#' \describe{
#' \item{pol}{Character; Pollutants: CH4(Methane), CO(Carbon Monoxide), 
#' CO2(Carbon Dioxide), N2O(Nitrous Oxide), NOx(Oxides of Nitrogen),
#'  PM10(Primary Exhaust PM10 - Total), PM25(Primary Exhaust PM2.5 - Total), SOX(Oxides of Sulfur),
#'  TOG(Total Organic Gases), ROG (Reactive Organic Gases)}
#' \item{reference_year}{Numeric; Year of reference between 2010 - 2020}
#' \item{fuel}{character; Type of fuel: 'D' (Diesel),'G' (Gasoline),'CNG' (Compressed Natural Gas).}
#' \item{model_year}{Model year.}
#' \item{speed}{Units; Speed in 'km/h'; Emission factor are returned in speed intervals 
#'  such as "5-10", "10-15", "15-20", "20-25", "25-30", "30-35", "35-40", "40-45", "45-50"
#'   "50-55", "55-60", "60-65", "65-70", "70-75", "75-80", "80-85", "85-90", ">90" mph (miles/h)}
#' }
#' @source \url{https://arb.ca.gov/emfac/emissions-inventory}
#' @family emission factor data
"ef_usa_emfac_db" # data(ef_usa_emfac_db)

#'  Emission factors from MOtor Vehicle Emission Simulator (MOVES)
#'  
#' Data.frame of emission factors for buses based on 
#' values from the [MOVES3 Model](https://www.epa.gov/moves).
#' Estimates expressed in units 'g/km'.
#'
#' @format  A data.table:
#' \describe{
#' \item{pollutant}{character; Pollutants: CH4 (Methane), CO (Carbon Monoxide), 
#' CO2 (Carbon Dioxide), EC (Energy Consumption), HONO (Nitrous Acid), 
#' N2O (Nitrous Oxide), NH3 (Ammonia),  NH4 (Ammonium), NO (Nitrogen Oxide), 
#' NO2 (Nitrogen Dioxide), NO3 (Nitrate), NOx (Oxides of Nitrogen),
#' PM10 (Primary Exhaust PM10 - Total), PM25 (Primary Exhaust PM2.5 - Total),
#' SO2 (Sulfur Dioxide), THC (Total Gaseous Hydrocarbons ), 
#' TOG (Total Organic Gases) and VOC (Volatile Organic Compounds)}
#' \item{fuel_type}{character; Type of fuel: 'D' (Diesel),'G' (Gasoline),'CNG'
#'  (Compressed Natural Gas).}
#' \item{reference_year}{Numeric; Calendar Year between 2015 - 2022. 
#' Year in which the emissions inventory is estimated.}
#' \item{model_year}{numeric; Model year of vehicle.}
#' \item{lower_speed_interval}{units 'km/h'; Represents the lower value of the 
#' speed intervals;  The speed intervals are " - 2.5", "2.5 - 7.5", "7.5 - 12.5"
#' , "12.5 - 17.5", "17.5 - 22.5", "22.5 - 27.5","27.5 - 32.5","32.5 - 37.5"
#' ,"37.5 - 42.5","42.5 - 47.5","47.5 - 52.5","52.5 - 57.5", "57.5 - 62.5"
#' , "62.5 - 67.5", "67.5 - 72.5", and ">72.5" mph (miles/h).}
#'  \item{upper_speed_interval}{units in km/h; Represents the upper value of the speed intervals.
#'  The speed intervals are analogous to `lower_speed_interval` above.}
#'  \item{source_type}{character; Type of vehicle, which currently has only "Transit Bus".}
#'  \item{id_speed}{integer;it caracterizes the types of vehicle speeds.}
#'  }
#' @source \url{https://www.epa.gov/moves}
#' @family emission factor data
"ef_usa_moves_db"  # data(ef_usa_moves_db)


#' Emission factors from Environment Company of Sao Paulo, Brazil (CETESB)
#' 
#' units 'g/km'; Emission factors for buses based on estimates from the 
#' Environment Company of Sao Paulo, Brazil (CETESB) 2017,
#' and obtained from [vein package](https://github.com/atmoschem/vein).
#' The R script used to organize the CETESB database can be found in the repository
#' <<https://github.com/ipea/gtfs2emis/blob/master/data-raw/ef_brazil_cetesb_db.R>>.
#'
#'
#' @format  A data.table:
#' \describe{
#' \item{pollutant}{ character; Pollutants: "CH4", "CO2", "PM10", "N2O", "KML", 
#' "FC" (Fuel Consumption), "gD/KWH", "gCO2/KWH", "CO", "HC" (Total Hydrocarbon), 
#' "NMHC" (Non-Methane Hydrocarbon), "NOx", "NO2", "NO", "RCHO", "ETOH",
#'  "FS"(Fuel Sales) and "NH3"}
#' \item{veh_type}{character; Vehicle categories by fuel:"BUS_URBAN_D", "BUS_MICRO_D", 
#' "BUS_COACH_D" and "BUS_ARTIC_D".}
#' \item{model_year}{numeric; Filter the emission factor to start from a specific 
#' base year. }
#' \item{as_list}{logical; Returns emission factors as a list, instead of data.table
#'  format.}
#' }
#' @family emission factor data
"ef_brazil_cetesb_db" # data(ef_brazil_cetesb_db)
