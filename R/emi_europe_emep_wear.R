#' @title 
#' Emissions from road vehicle tyre, brake, and surface wear from the European 
#' Environment Agency (EMEP/EEA) model 
#' 
#' @description 
#' Returns a list or data.table of emissions for urban buses based on Tier 2 of 
#'  EMEP/EEA air pollutant emission inventory guidebooks (2019). The function concerns 
#'  the emissions of particulate matter (PM), encompassing black carbon (BC) (1), 
#'  which arises from distinct sources, namely, road vehicle tire and brake wear 
#'  (NFR code 1.A.3.b.vi), and road surface wear (NFR code 1.A.3.b.vii). It is 
#'  important to note that PM emissions exhaust from vehicle exhaust are excluded. 
#'  The focus is on primary particles, which refer to those that are directly 
#'  emitted due to surface wear, rather than those generated from the 
#'  resuspension of previously deposited material. See more in @details.
#'  
#' @param dist units; Length of each link in 'km'.
#' @param speed units; Speed in 'km/h'.
#' @param pollutant character; Pollutant, classified in "TSP"(Total Suspended Particles),
#'  "PM10","PM2.5", "PM1.0","PM0.1". Please note that emissions factors for 
#'  "PM1.0" and "PM0.1" are  not available for road surface wear process.
#' @param veh_type character; Bus type, classified in "Ubus Midi <=15 t",
#' "Ubus Std 15 - 18 t", "Ubus Artic >18 t", "Coaches Std >18 t", or "Coaches Artic >18 t".
#' @param fleet_composition vector; Fleet composition, which is a distribution 
#' of fleet based on frequency. If there is only one, 'fleet_composition' is 1.0.
#' @param load numeric; Load ratio, classified in 0.0, 0.5 and 1.0. Default is 0.5.
#' @param process character; Emission process sources, classified in "tyre","brake" and/or 
#' "road".
#' @param as_list logical; Returns emission factors as a list, instead of data.table format. Default is TRUE.
#' 
#' @return  List. emission in units 'g' (list or a data.table).
#' @details 
#' 
#' The following equation is employed to evaluate emissions originating from tyre
#'  and brake wear
#' 
#' TE(i) = dist x EF_tsp(j) x mf_s(i) x sc(speed),
#' 
#' where:
#' - TE(i)      = total emissions of pollutant i (g),
#' - dist       = distance driven by each vehicle (km),
#' - EF_tsp(j)  = TSP mass emission factor for vehicles of category j (g/km),
#' - mf_s(i)    = mass fraction of TSP that can be attributed to particle size class i,
#' - sc(speed)  = correction factor for a mean vehicle travelling at a given speed (-)
#' 
#' *Tyre*
#' 
#' In the case of heavy-duty vehicles, the emission factor needs the 
#' incorporation of vehicle size, as determined by the number of axles, and load.
#'  These parameters are introduced into the equation as follows:
#'  
#'  EF_tsp_tyre_hdv = 0.5 x N_axle x LCF_tyre x EF_tsp_tyre_pc
#'  
#'  where
#'  - EF_tsp_tyre_hdv  = TSP emission factor for tyre wear from heavy-duty 
#'  vehicles (g/km),
#'  - N_axle           = number of vehicle axles (-),
#'  - LCF_t            = a load correction factor for tyre wear (-),
#'  - EF_tsp_tyre_pc   = TSP emission factor for tyre wear from passenger car 
#'  vehicles (g/km).
#' 
#' and
#'  LCF_tyre = 1.41 + (1.38 x LF),
#'  
#'  where:
#'  - LF = load factor (-), ranging from 0 for an empty bus to 1 for a fully laden one.
#'  
#'  The function considers the following look-up table for number of vehicle axes:
#'  
#'  | vehicle class (j)   | number of axes |
#'  | ------------------- | -------------- |
#'  | Ubus Midi <=15 t    |       2        |
#'  | Ubus Std 15 - 18 t  |       2        |
#'  | Ubus Artic >18 t    |       3        |
#'  | Coaches Std <=18 t  |       2        |
#'  | Coaches Artic >18 t |       3        |
#'  
#'  The size distribution of tyre wear particles are given by:
#'  
#'  | particle size class (i)  | mass fraction of TSP |
#'  | -----------------------  | -------------------- |
#'  |         TSP              |       1.000          |
#'  |         PM10             |       0.600          |
#'  |         PM2.5            |       0.420          |
#'  |         PM1.0            |       0.060          |
#'  |         PM0.1            |       0.048          |
#'   
#'  Finally, the speed correction is:
#'  
#'  sc_tyre(speed) = 1.39, when V < 40 km/h;
#'  sc_tyre(speed) = -0.00974 x speed + 1.78, when 40 <= speed <= 90 km/h;
#'  sc_tyre(speed) = 0.902, when speed > 90 km/h.
#'   
#'  *Brake*
#'   
#'  The heavy-duty vehicle emission factor is derived by modifying the passenger
#'  car emission factor to conform to experimental data obtained from 
#'  heavy-duty vehicles.
#'   
#'  EF_tsp_brake_hdv = 1.956 x LCF_brake x EF_tsp_brake_pc
#'  
#'  where:
#'  - EF_tsp_brake_hdv  = heavy-duty vehicle emission factor for TSP, 
#'  - LCF_brake         = load correction factor for brake wear,
#'  - EF_tsp_brake_pc   = passenger car emission factor for TSP,
#'   
#' and
#'  LCF_brake = 1 + (0.79 x LF),
#'  
#'  where:
#'  - LF = load factor (-), ranging from 0 for an empty bus to 1 for a fully laden one.
#' 
#' The size distribution of brake wear particles are given by:
#'  
#'  | particle size class (i)  | mass fraction of TSP |
#'  | -----------------------  | -------------------- |
#'  |         TSP              |       1.000          |
#'  |         PM10             |       0.980          |
#'  |         PM2.5            |       0.390          |
#'  |         PM1.0            |       0.100          |
#'  |         PM0.1            |       0.080          |
#' 
#' Finally, the speed correction is:
#'  
#'  sc_brake(speed) = 1.67, when V < 40 km/h;
#'  sc_brake(speed) = -0.0270 x speed + 2.75, when 40 <= speed <= 95 km/h;
#'  sc_brake(speed) = 0.185, when speed > 95 km/h.
#' 
#' *Road Wear*
#' 
#' Emissions are calculated according to the equation:
#' 
#' TE(i) = dist x EF_tsp_road(j) x mf_road
#' 
#' where:
#' - TE          = total emissions of pollutant i (g),
#' - dist        = total distance driven by vehicles in category j (km),     
#' - EF_tsp_road = TSP mass emission factor from road wear for vehicles j (0.0760 g/km),   
#' - mf_road     = mass fraction of TSP that can be attributed to particle size
#' class i (-).
#'  
#'  The following table shows the size distribution of road surface wear particles
#'  
#'  | particle size class (i)  | mass fraction of TSP |
#'  | -----------------------  | -------------------- |
#'  |         TSP              |        1.00          |
#'  |         PM10             |        0.50          |
#'  |         PM2.5            |        0.27          |
#' 
#' *References*
#' 
#' #' EMEP/EEA data and reports can be accessed in the following links:
#'  - 2019 edition \url{https://www.eea.europa.eu/en/analysis/publications/emep-eea-guidebook-2019/}.
#'  
#' @family Emission factor model
#' 
#' @export
#' 
#' @examples
#' emi_europe_emep_wear(dist = units::set_units(1,"km"),
#'                      speed =  units::set_units(30,"km/h"),
#'                      pollutant = c("PM10","TSP","PM2.5"),
#'                      veh_type = c("Ubus Std 15 - 18 t","Ubus Artic >18 t"),
#'                      fleet_composition = c(0.5,0.5),
#'                      load = 0.5,
#'                      process = c("brake","tyre","road"),
#'                      as_list = TRUE)
emi_europe_emep_wear <- function(dist,speed,pollutant,veh_type,
                     fleet_composition,load = 0.5,process = "tyre",as_list = TRUE){
  
  # dist = units::set_units(tp_model$dist, "km") 
  # speed = units::set_units(tp_model$speed, "km/h")
  # pollutant = "PM10"
  # veh_type = my_fleet$veh_type
  # fleet_composition = my_fleet$fleet_composition
  # load = 0.5
  # process = c("tyre","brake","road")
  # as_list = TRUE
  # check inputs ----------
  # speed
  assert_vector(speed,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(speed,lower = 1,upper = 130)
  assert_class(speed,"units")
  if(units(speed)$numerator != "km" | units(speed)$denominator != "h"){
    cli::cli_abort(c("{.arg speed} must be in {.val km/h}."
                     , "x" = "It has units {.val {units::deparse_unit(speed)}}.")
                   , class = "gtfs2emis_error")
  }
  # dist
  assert_vector(dist,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(dist,any.missing = FALSE,min.len = 1)
  assert_class(dist,"units")
  if(units(dist)$numerator != "km"){
    cli::cli_abort(c("{.arg dist} must be in {.val km}."
                     , "x" = "It has units {.val {units::deparse_unit(dist)}}.")
                   , class = "gtfs2emis_error")
  }
  # length dist and speed
  checkmate::check_true(length(speed) == length(dist),na.ok = FALSE)
  # veh_type
  assert_vector(veh_type,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_class(veh_type,"character")
  names_veh <- c("Ubus Midi <=15 t","Ubus Std 15 - 18 t","Ubus Artic >18 t"
                 ,"Coaches Std <=18 t","Coaches Artic >18 t")
  for(i in veh_type) assert_choice(i,names_veh, .var.name = "veh_type")
  # process
  assert_vector(process,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_class(process,"character")
  name_process <- c('tyre','brake','road')
  for(i in process) assert_choice(i,name_process, .var.name = "process")
  # pollutant
  assert_vector(pollutant,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(pollutant,any.missing = FALSE,min.len = 1)
  for(i in process){
    if(i != "road"){
      for(j in pollutant) assert_choice(j,c('TSP','PM10','PM2.5','PM1.0','PM0.1'),null.ok = FALSE, .var.name = "pollutant")
    }else{
      for(j in pollutant) assert_choice(j,c('TSP','PM10','PM2.5'),null.ok = FALSE, .var.name = "pollutant")
    }
  }
  # fleet_composition
  assert_vector(fleet_composition,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(fleet_composition,any.missing = FALSE,min.len = 1,lower = 0,upper = 1)
  # load factor
  assert_vector(load,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(load,lower = 0,upper = 1)
  assert_class(load,"numeric")
  if(length(load) != 1){
    checkmate::check_true(length(load) == length(dist),na.ok = FALSE)
    checkmate::check_true(length(load) == length(speed),na.ok = FALSE)
  }
  # as_list
  assert_logical(as_list, any.missing = FALSE) 
  
  # Adjust lengths
  # check lengths----
  if(length(fleet_composition) != length(veh_type) && length(veh_type) == 1){
    tmp_veh_type <- rep(veh_type,length(fleet_composition))
  }else{
    tmp_veh_type <- veh_type
  }
  # internal functions
  speed_cor_tw_f <- function(speed){
    st <- vector(length = length(speed))
    # interv. 1
    st[speed < units::set_units(40,'km/h')] <- 1.39
    # interv. 2
    id_speed <- which(speed >= units::set_units(40,'km/h') & 
                        speed <= units::set_units(90,'km/h'))
    st[id_speed] <- -0.00974 * as.numeric(speed[id_speed]) + 1.78
    # interv. 3
    st[speed > units::set_units(90,'km/h')] <- 0.902
    return(st)
  }
  speed_cor_bw_f <- function(speed){
    sb <- vector(length = length(speed))
    # interv. 1
    sb[speed < units::set_units(40,'km/h')] <- 1.67
    # interv. 2
    id_speed <- which(speed >= units::set_units(40,'km/h') & 
                        speed <= units::set_units(95,'km/h'))
    sb[id_speed] <- -0.0270 * as.numeric(speed[id_speed]) + 2.75
    # interv. 3
    sb[speed > units::set_units(90,'km/h')] <- 0.185
    return(sb)
  }
  # internal tables from EMEP
  # tyre wear | break wear
  size_class <- data.table::data.table("pol" = c('TSP','PM10','PM2.5','PM1','PM0.1')
                                       ,"mf_tw" = c(1.000,0.600,0.420,0.060,0.048)
                                       ,"mf_bw" = c(1.000,0.980,0.390,0.100,0.080)
                                       ,"mf_rs" = c(1.000,0.500,0.270,NA    ,NA  ))
  # number of axles
  n_axle_table <- data.table::data.table(veh = c("Ubus Midi <=15 t"
                                                 ,"Ubus Std 15 - 18 t"
                                                 ,"Ubus Artic >18 t"
                                                 ,"Coaches Std <=18 t"
                                                 ,"Coaches Artic >18 t")
                                         ,n_axle = c(2,2,3,2,3))
  # emissions process
  emi_wear <- function(pollutant,process){
    if(process == "tyre"){
      # load correction factor
      lcf_tw <- 1.41 + 1.38 * load
      # number of axles
      n_axle <- n_axle_table[veh %in% tmp_veh_type,n_axle]
      # emission factor
      ef_tsp_pc_tw <- units::set_units(0.0107,'g/km')
      ef_tsp_bus_tw <- as.matrix(n_axle * fleet_composition) %*%  t(lcf_tw * ef_tsp_pc_tw * 0.5)
      ef_tsp_bus_tw <- t(ef_tsp_bus_tw)
      # mass fraction
      mass_tw <- size_class[pol %in% pollutant,mf_tw]
      # speed correction
      speed_cor_tw <- speed_cor_tw_f(speed)
      # emission
      tmp1 <- (dist * speed_cor_tw) %*% as.matrix(t(mass_tw))
      tmp2 <- lapply(1:ncol(ef_tsp_bus_tw),function(i){ef_tsp_bus_tw[,i] * tmp1})
      tmp_emi <- do.call(cbind,tmp2)
      tmp_emi <- units::set_units(tmp_emi,"g")
    }
    if(process == "brake"){
      # load factor
      lcf_bw <- 1.00 + 0.79 * load
      # mass fraction
      mass_bw <- size_class[pol %in% pollutant,mf_bw]
      # emission factor
      ef_tsp_pc_bw <-  0.0075 # g/km
      ef_tsp_bus_bw <- 1.956 * lcf_bw * ef_tsp_pc_bw
      #ef_tsp_bus_bw <- units::set_units(ef_tsp_bus_bw,'g/km')
      # speed corrections
      speed_cor_bw <- speed_cor_bw_f(speed)
      # emission
      tmp_emi <- as.matrix(ef_tsp_bus_bw) %*% as.matrix(t((fleet_composition * mass_bw)))
      tmp2 <- as.matrix(dist) * speed_cor_bw
      tmp3 <- lapply(1:ncol(tmp_emi),function(i){tmp2 %*% tmp_emi[,i]})
      tmp3 <- do.call(cbind,tmp3)
      tmp_emi <- units::set_units(tmp3,"g")
    }
    if(process == "road"){
      ef_tsp_bus_rs <- units::set_units(0.0760,'g/km')
      # emission factor - urban bus
      mass_rs <- size_class[pol == pollutant,mf_rs]
      # emission
      tmp_emi <- dist * ef_tsp_bus_rs * mass_rs 
      tmp_emi <- as.matrix(tmp_emi) %*% as.matrix(t(fleet_composition))
      tmp_emi <- units::set_units(tmp_emi,"g")
    }
    tmp_emi <- data.table::as.data.table(tmp_emi)
    names(tmp_emi) <- paste0(pollutant,"_",process,"_veh_",1:ncol(tmp_emi))
    return(tmp_emi)
  }
  tmp_emi <- lapply(process,function(i){ # i = "brake"
    tmp_emi1 <- lapply(pollutant,emi_wear,i)
    tmp_emi1 <- do.call(cbind,tmp_emi1)
    return(tmp_emi1)
  }) 
  tmp_emi <- do.call(cbind,tmp_emi)
  
 # names(tmp_emi)
  
  if(as_list){
    # local test
    emi_final <- list("pollutant" = pollutant, 
                      "veh_type" =  veh_type, 
                      "fleet_composition" = fleet_composition, 
                      "speed" = units::set_units(speed,"km/h"),
                      "dist" = units::set_units(dist,"km"),
                      "emi" = tmp_emi,
                      "process" = process) 
  }else{
    emi_final <- tmp_emi
  }
  return(emi_final)
}