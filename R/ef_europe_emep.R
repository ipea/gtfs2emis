#' @title 
#' Speed-dependent emission factor from the European Environment Agency (EMEP/EEA) model 
#' 
#' @description 
#' Returns a list or data.table of emission factors for buses based on EMEP/EEA air pollutant
#'  emission inventory guidebooks. The function uses four emission factor databases 
#'  published by EMEP/EEA, considering the editions of 2019, 2016, 2013 and 2007. 
#'  Estimates are expressed in units 'g/km'. See more in @details.  
#' 
#' @param speed units; Speed in 'km/h'.
#' @param veh_type character; Bus type, classified in "Ubus Midi <=15 t","Ubus Std 15 - 18 t","Ubus Artic >18 t",
#' "Coaches Std <=18 t","Coaches Artic >18 t".
#' @param euro character; Euro period of vehicle, classified in "Conventional", "I", "II", "III", "IV", "V", "VI", and "EEV".
#' @param pollutant character; Pollutant, classified in "FC","CO2","CO","NOx","VOC","PM10","EC","CH4","NH3","N2O". "FC" is fuel consumption (g/km).
#' "EC" is energy consumption in MJ/km, although it is returned with g/km units. FC and CO2 are not available
#' for every combination (e.g. there is no CO2 for "BD" or for "Conventional" diesel buses).
#' @param fuel character; Fuel type, classified in "D" (Diesel),"DHD" (Diesel Hybrid ~ Diesel),
#' "DHE" (Diesel Hybrid ~ Electricity), "CNG" (Compressed Natural Gas), "BD" (Biodiesel).   
#' @param tech character; After treatment technology, classified in "SCR" (Selective Catalytic Reduction), 
#' "EGR" (Exhaust Gas Recirculation), and "DPF+SCR" (Diesel Particulate Filter + SCR, for Euro VI). Default is "SCR" for "IV" and "V". There are 
#' no available after treatment technology associated with euro standards "Conventional", "I", "II" and "III". 
#' @param slope numeric; Slope gradient, classified in -0.06, -0.04, -0.02, 0.00, 0.02, 0.04 and 
#' 0.06. Negative gradients means downhills and positive uphills. Default is 0.0.
#' @param load numeric; Load ratio, classified in 0.0, 0.5 and 1.0. Default is 0.5.
#' @param fcorr numeric; Correction based on fuel composition. The length must be one per
#' each euro standards. Default is 1.0.
#' @param as_list logical; Returns emission factors as a list, instead of data.table format. Default is TRUE.
#' 
#' @return List. emission factors in units 'g/km' (list or a data.table).
#' @details 
#' 
#' The new convention for vehicles names are translated from the EMEP/EEA report:
#' 
#' | vehicle category    | description                                              |
#' | ------------------  | -------------------------------------------------------- |
#' | Ubus Midi <=15 t    | Urban Bus Midi size, Gross Vehicle Weight (GVW) <= 15 tons |
#' | Ubus Std 15 - 18 t  | Urban Bus Standard size, GVW between 15 - 18 tons |
#' | Ubus Artic >18 t    | Urban Bus Articulated size, GVW >= 18 tons |
#' | Coaches Std <=18 t  | Coach (inter-state) Standard size, GVW <= 18 tons |
#' | Coaches Artic >18 t | Coach (inter-state) Articulated size, GVW > 18 tons |
#' 
#' When the information of vehicle technology does not match the existing database, 
#' the function display a message mentioning the returned technology. 
#' User can either select an existing data for the combining variables 
#' (`euro`, `tech`, `veh_type` and `pollutant`), or accept the assumed change 
#' in vehicle technology.
#' 
#' In order to cover more pollutants, vehicle technologies, and fuel consumption data, 
#' the function uses four emission factor databases published by EMEP/EEA, 
#' considering the editions of 2019, 2016, 2013 and 2007.  
#'  
#' The R scripts used to download and pre-process 4 EMEP/EEA editions (2019, 2016, 2013 and 2007)
#' can be accessed in the 'gtfs2emis' GitHub repository at
#' <<https://github.com/ipeaGIT/gtfs2emis/blob/master/data-raw/ef_europe_emep_db.R>>  
#' 
#' EMEP/EEA data and reports can be accessed in the following links:
#'  - 2019 edition \url{https://www.eea.europa.eu/en/analysis/publications/emep-eea-guidebook-2019/part-b-sectoral-guidance-chapters/1-energy/},
#'  - 2016 edition \url{https://www.eea.europa.eu/publications/emep-eea-guidebook-2016/},
#'  - 2013 edition \url{https://www.eea.europa.eu/publications/emep-eea-guidebook-2013/}, and
#'  - 2007 edition \url{https://www.eea.europa.eu/publications/EMEPCORINAIR5/}.
#' 
#' @family Emission factor model
#' 
#' @export
#' 
#' @examples
#' ef_europe_emep( speed = units::set_units(1:100,"km/h"),
#'                 veh_type = c("Ubus Midi <=15 t","Ubus Std 15 - 18 t","Ubus Artic >18 t"),
#'                 euro = c("IV","V"),
#'                 fuel = "D",
#'                 pollutant = c("CO","PM10","CH4","NOx"),
#'                 as_list = FALSE) 
ef_europe_emep <- function(speed, veh_type, euro,  pollutant, fuel = "D", tech = "SCR", 
                           slope = 0.0, load = 0.5, fcorr = 1, as_list = TRUE){
  call <- rlang::current_env()  # header for conditions raised inside closures
  
  # speed = gpsLine$speed
  # veh_type = "Ubus Std 15 - 18 t"
  # euro = "V"
  # pollutant = "PM10"
  # fuel = "D"
  # tech = "SCR"
  # slope = gpsLineclass$slope
  # load = 0.5
  # fcorr = 1
  # as_list = TRUE
  
  
  # euro data----
  utils::data('ef_europe_emep_db') 
  temp_ef <- ef_europe_emep_db
  
  
  # check inputs ----
  # speed
  assert_vector(speed,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(speed,lower = 1,upper = 130)
  assert_class(speed,"units")
  if(units(speed)$numerator != "km" | units(speed)$denominator != "h"){
    cli::cli_abort(c("{.arg speed} must be in {.val km/h}."
                     , "x" = "It has units {.val {units::deparse_unit(speed)}}.")
                   , class = "gtfs2emis_error")
  }
  # vehicle type
  assert_vector(veh_type,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(veh_type,any.missing = FALSE,min.len = 1)
  for(i in veh_type) assert_choice(i,unique(temp_ef$Segment),null.ok = FALSE, .var.name = "veh_type")
  # euro
  assert_vector(euro,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(euro,any.missing = FALSE,min.len = 1)
  for(i in euro) assert_choice(i,unique(temp_ef$Euro),null.ok = FALSE, .var.name = "euro")
  # fuel
  assert_vector(fuel,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(fuel,any.missing = FALSE,min.len = 1)
  for(i in fuel) assert_choice(i,unique(temp_ef$Fuel),null.ok = FALSE, .var.name = "fuel")
  # pollutant
  assert_vector(pollutant,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(pollutant,any.missing = FALSE,min.len = 1)
  for(i in pollutant) assert_choice(i,unique(temp_ef$Pol),null.ok = FALSE, .var.name = "pollutant")
  # technology
  assert_vector(tech,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(tech,any.missing = FALSE,min.len = 1)
  for(i in tech) assert_choice(i,unique(temp_ef$Technology),null.ok = FALSE, .var.name = "tech")
  # as_list
  assert_logical(as_list, any.missing = FALSE) 
  
  # speed----
  
  speed <- round(as.numeric(speed))
  tmpSpeed <- unique(speed)
  
  # check lengths----
  
  if(length(euro) != length(veh_type) && length(veh_type) == 1){
    veh_type <- rep(veh_type,length(euro))
  }
  if(length(euro) != length(tech) && length(tech) == 1){
    tech <- rep(tech,length(euro))
  }
  if(length(euro) != length(fuel) && length(fuel) == 1){
    fuel <- rep(fuel,length(euro))
  }
  if(length(fcorr) == 1)  fcorr <- rep(fcorr,length(euro))
  if(length(slope) == 1)  slope <- rep(slope,length(speed))
  if(length(load)  == 1)  load  <- rep(load,length(speed))
  if(length(fcorr) == 1)  fcorr <- rep(fcorr,length(euro))
  
  if(length(slope) > 1 & (length(slope) != length(speed)) ){
    cli::cli_abort("{.arg slope} and {.arg speed} must have the same length."
                   , class = "gtfs2emis_error")
  }
  if(length(load) > 1 & (length(load) != length(speed)) ){
    cli::cli_abort("{.arg load} and {.arg speed} must have the same length."
                   , class = "gtfs2emis_error")
  }
  
  # polynomial expression----
  
  eq_num <- function(Alpha,Beta,Gamma,Delta,Epsilon,Zita,Hta,RF,Speed,Function_ID,k,fcorr){
    switch(Function_ID,
           "1" = (Alpha * (Speed ^ 2) + Beta * Speed + Gamma + Delta / Speed)/(Epsilon * (Speed ^ 2) + Zita * Speed + Hta) * (1 - RF) * k * fcorr
           ,"2019_1"  = (Alpha * (Speed ^ 2) + Beta * Speed + Gamma + Delta / Speed)/(Epsilon * (Speed ^ 2) + Zita * Speed + Hta) * (1-RF) * k * fcorr
           ,"2013_3"  = (((Alpha * (Beta ^ Speed)) * (Speed ^ Gamma))) * k * fcorr
           ,"2013_12" = ((Alpha / (1 + (Beta * exp(((-1) * Gamma) * Speed))))) * k * fcorr
           ,"2013_9"  = ((1 / (Alpha + (Beta * (Speed ^ Gamma))))) * k * fcorr
           ,"2013_11" = ((Alpha - (Beta * exp(((-1) * Gamma) * (Speed ^ Delta))))) * k * fcorr
           ,"2013_4"  = (((Alpha * (Speed ^ Beta)) + (Gamma * (Speed ^ Delta)))) * k * fcorr
           ,"2013_16" = (exp((Alpha + (Beta / Speed)) + (Gamma * log(Speed)))) * k * fcorr
           ,"2013_10" = ((1 / (Alpha + (Beta * Speed)))) * k * fcorr
           ,"2013_1"  = (((((Alpha * (Speed ^ 3)) + (Beta * (Speed ^ 2))) + (Gamma * Speed)) + Delta)) * k * fcorr
           ,"2007_1"  = ((Epsilon + (Alpha * exp(((-1) * Beta) * Speed))) + (Gamma * exp(((-1) * Delta) * Speed))) * k * fcorr
           ,"2007_2"  = ((Alpha * (Beta ^ Speed)) * (Speed ^ Gamma)) * k * fcorr
           ,"2007_3"  = ((Alpha * (Speed^Beta)) + (Gamma * (Speed ^ Delta))) * k * fcorr
           ,"2007_4"  = (Alpha + (Beta/(1 + exp((((-1) * Gamma)+(Delta * log(Speed)))+(Epsilon * Speed))))) * k * fcorr
           ,"2007_5"  = ((Alpha + (Beta * Speed)) + (((Gamma-Beta)*(1-exp(((-1) * Delta) * Speed)))/Delta)) * k * fcorr
           ,"2007_6"  = (Gamma + (Alpha * exp(Beta * Speed))) * k * fcorr
           ,"2007_7"  = ((((Alpha * (Speed ^ 3))+(Beta * (Speed^2)))+(Gamma * Speed)) + Delta) * k * fcorr
           ,"2007_9"  = (1/(((Gamma * (Speed ^ 2))+(Beta * Speed)) + Alpha)) * k * fcorr
           ,"2007_10" = (Alpha/(1+(Beta * exp(((-1) * Gamma) * Speed)))) * k * fcorr
           ,"2007_11" = exp((Alpha + (Beta / Speed))+(Gamma * log(Speed))) * k * fcorr
           ,"2007_8"  =  (Gamma + (Alpha * exp(((-1) * Beta) * Speed))) * k * fcorr
    ) }
  
  # emission factor----
  
  temp_ef1 <- lapply(seq_along(pollutant),function(i){  # i = 1
    temp_ef2 <- lapply(seq_along(euro),function(j){    # i=1;j = 1
      
      #message(sprintf("i=%s, j=%s",i,j))
      # condition for missing technologies
      
      if(euro[j] %in%  c("Conventional","I","II","III") &  tech[j] != "-"){
        cli::cli_inform(c(paste0("{.val {pollutant[i]}} emission factor not found for technology "
                                 , "{.val {tech[j]}} and Euro {.val {euro[j]}}.")
                        , "i" = paste0("The package assumes missing Technology entry. Check "
                                       , "{.code data(ef_europe_emep_db)} for available data.")))
        tech[j] = "-"
      }
      # FC / CO2 with tech
      if((euro[j] %in%  c("V","VI")) && (pollutant[i] %in% c("FC","CO2")) & 
         tech[j] == "-"){
        cli::cli_inform(c(paste0("{.val {pollutant[i]}} emission factor not found for technology "
                                 , "{.val {tech[j]}} and Euro {.val {euro[j]}}.")
                        , "i" = paste0("The package assumed 'SCR' Technology entry. Check "
                                       , "{.code data(ef_europe_emep_db)} for available data.")))
        tech[j] = "SCR"
      }
      # FC / CO2 without tech
      if(!(euro[j] %in%  c("V","VI")) && (pollutant[i] %in% c("FC","CO2")) & 
         tech[j] != "-"){
        cli::cli_inform(c(paste0("{.val {pollutant[i]}} emission factor not found for technology "
                                 , "{.val {tech[j]}} and Euro {.val {euro[j]}}.")
                        , "i" = paste0("The package assumes missing Technology entry. Check "
                                       , "{.code data(ef_europe_emep_db)} for available data.")))
        tech[j] = "-"
      }
      # FC / CO2 with tech
      if((euro[j] %in%  c("V","VI")) && (pollutant[i] %in% c("FC","CO2")) & 
         (tech[j] %in% c("-","DPF+SCR"))){
        cli::cli_inform(c(paste0("{.val {pollutant[i]}} emission factor not found for technology "
                                 , "{.val {tech[j]}} and Euro {.val {euro[j]}}.")
                        , "i" = paste0("The package assumed 'SCR' Technology entry. Check "
                                       , "{.code data(ef_europe_emep_db)} for available data.")))
        tech[j] = "SCR"
      }
      # EURO VI
      if((euro[j] %in%  c("VI")) && !(pollutant[i] %in% c("CO2","FC")) & tech[j] != "DPF+SCR"){
        cli::cli_inform(c(paste0("{.val {pollutant[i]}} emission factor not found for technology "
                                 , "{.val {tech[j]}} and Euro {.val {euro[j]}}.")
                        , "i" = paste0("The package assumed 'DPF+SCR' Technology entry. Check "
                                       , "{.code data(ef_europe_emep_db)} for available data.")))
        tech[j] = "DPF+SCR"
      }
      
      # fix load and slope
      
      if(length(unique(slope)) > 1 | length(unique(load)) > 1){
        #slope_input <- slope 
        temp_ef3 <- lapply(seq_along(slope),function(k){ # k = 1
          as.data.frame(temp_ef)[ temp_ef$Pol %in% pollutant[i] &  
                                    temp_ef$Fuel %in% fuel[j] & 
                                    temp_ef$Segment %in% veh_type[j] & 
                                    temp_ef$Technology %in% tech[j] &
                                    temp_ef$Euro %in% euro[j] & 
                                    temp_ef$Slope == slope[k] & 
                                    temp_ef$Load == load[k], ]
        }) 
        temp_ef3 <- data.table::rbindlist(temp_ef3)
        
      }else{
        temp_ef3 <- temp_ef[ Pol %in% pollutant[i] &  
                               Fuel %in% fuel[j] & 
                               Segment %in% veh_type[j] & 
                               Technology %in% tech[j] &
                               Euro %in% euro[j] & 
                               Slope == slope[1] & 
                               Load == load[1], ]
      }
      
      #
      # no EF case
      #
      
      if(nrow(temp_ef3) == 0){
        cli::cli_abort(c("No available emission factor for this combination of parameters:"
                         , "*" = "Pol: {.val {pollutant[i]}}"
                         , "*" = "Fuel: {.val {fuel[j]}}"
                         , "*" = "Segment: {.val {veh_type[j]}}"
                         , "*" = "Technology: {.val {tech[j]}}"
                         , "*" = "Euro: {.val {euro[j]}}"
                         , "*" = "Slope: {.val {slope[1]}}"
                         , "*" = "Load: {.val {load[1]}}"
                         , "i" = "Check {.code data(ef_europe_emep_db)} for available data.")
                       , class = c("gtfs2emis_missing_ef", "gtfs2emis_error")
                       , call = call)
      }
      
      
      
      #
      # Ef estimates
      #
      if(length(unique(slope)) > 1 | length(unique(load)) > 1){
        
        data_speed <- lapply(seq_along(slope),function(k){ # k =1
          
          # select slope specific
          temp_ef4 <- as.data.frame(temp_ef3)[temp_ef3$Slope == slope[k] & 
                                                temp_ef3$Load == load[k], ]
          
          # fix speed
          tmpSpeedPol <- speed[k]
          tmpSpeedPol[tmpSpeedPol < temp_ef4$Vmin] <- temp_ef4$Vmin
          tmpSpeedPol[tmpSpeedPol > temp_ef4$Vmax] <- temp_ef4$Vmax
          
          tmp_eq <- eq_num(Alpha = temp_ef4$Alpha
                           , Beta = temp_ef4$Beta
                           , Gamma = temp_ef4$Gamma
                           , Delta = temp_ef4$Delta
                           , Epsilon = temp_ef4$Epsilon
                           , Zita = temp_ef4$Zita
                           , Hta = temp_ef4$Hta
                           , RF = temp_ef4$RF
                           , Speed = tmpSpeedPol
                           , Function_ID = temp_ef4$Function_ID
                           , k = temp_ef4$k
                           , fcorr = fcorr[j])
          
          eq_output <- data.table::data.table("ef" = tmp_eq, "tmpSpeed" = tmpSpeedPol)
          
          return(eq_output)
          
        }) 
        eq_output <- data.table::rbindlist(data_speed)
        eq_output <- eq_output$ef
      
        }else{
        
        # fix speed
        tmpSpeedPol <- tmpSpeed
        tmpSpeedPol[tmpSpeedPol < temp_ef3$Vmin] <- temp_ef3$Vmin
        tmpSpeedPol[tmpSpeedPol > temp_ef3$Vmax] <- temp_ef3$Vmax
        
        tmp_eq <- eq_num(Alpha = temp_ef3$Alpha
                         , Beta = temp_ef3$Beta
                         , Gamma = temp_ef3$Gamma
                         , Delta = temp_ef3$Delta
                         , Epsilon = temp_ef3$Epsilon
                         , Zita = temp_ef3$Zita
                         , Hta = temp_ef3$Hta
                         , RF = temp_ef3$RF
                         , Speed = tmpSpeedPol
                         , Function_ID = temp_ef3$Function_ID
                         , k = temp_ef3$k
                         , fcorr = fcorr[j])
        
        data_speed <- data.table::data.table("ef" = tmp_eq, "tmpSpeed" = tmpSpeed)
        
        # expands speed---
        
        data.table::setkey(data_speed,tmpSpeed)
        eq_output <- data_speed[data.table::data.table(speed)]$ef
        
      }

      return(eq_output)
    })
    
    #
    # do not aggregate EF
    #
    
    temp_ef3 <- do.call(cbind, temp_ef2) 
    temp_ef3 <- units::set_units(temp_ef3,'g/km') 
    temp_ef3 <- data.table::as.data.table(temp_ef3)
    
    names(temp_ef3) <- sprintf("%s_Euro_%s",pollutant[i],rep(euro))
    return(temp_ef3)
  })
  
  # return in a data.table/list like format----
  
  ef_final <- do.call(cbind, temp_ef1)
  
  if(as_list){
    # local test
    ef_final <- list("pollutant" = pollutant,
                     "veh_type" = veh_type,
                     "euro" = euro,
                     "fuel" = fuel,
                     "tech" = tech,
                     "process" = "hot_exhaust",
                     "slope" = slope,
                     "load" = load,
                     "speed" = units::set_units(speed,"km/h"),
                     "EF" = ef_final)
   #ef_final <- list("pollutant" = rep(pollutant,each = length(veh_type)),
   #                 "veh_type" = rep(veh_type,length(pollutant)),
   #                 "euro" = rep(euro,length(pollutant)),
   #                 "fuel" = rep(fuel,length(pollutant)),
   #                 "tech" = rep(tech,length(pollutant)),
   #                 "slope" = slope,
   #                 "load" = load,
   #                 "speed" = units::set_units(speed,"km/h"),
   #                 "EF" = ef_final)
  }
  
  return(ef_final)
}
