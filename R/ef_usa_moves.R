#' @title 
#' Running exhaust emissions factors for buses from United States (MOVES3 model)
#' 
#' @description 
#' Returns a vector or data.frame of emission factors for urban buses based on 
#' values from the [MOVES3 Model](https://www.epa.gov/moves). Emission factor 
#' estimates are expressed in units 'g/km'.
#' 
#' @param pollutant character. Pollutants: "CH4" (Methane), "CO" (Carbon 
#'        Monoxide), "CO2" (Carbon Dioxide), "EC" (Energy Consumption), "HONO" 
#'        (Nitrous Acid), "N2O" (Nitrous Oxide), "NH3" (Ammonia ), "NH4" 
#'        (Ammonium), "NO" (Nitrogen Oxide), "NO2" (Nitrogen Dioxide), "NO3" 
#'        (Nitrate), "NOx" (Oxides of Nitrogen), "PM10" (Primary Exhaust PM10 - 
#'        Total), "PM25" (Primary Exhaust PM2.5 - Total), "SO2" (Sulfur Dioxide),
#'        "THC" (Total Gaseous Hydrocarbons ), "TOG" (Total Organic Gases) and 
#'        "VOC" (Volatile Organic Compounds)
#' @template reference_year
#' @template fuel
#' @param model_year numeric. Model year of vehicle.
#' @param speed units. Speed in 'km/h'. Emission factor are returned in speed 
#'        intervals: "0-2.5", "2.5-7.5", "7.5-12.5", "12.5-17.5", "17.5-22.5", 
#'        "22.5-27.5", "27.5-32.5", "32.5-37.5", "37.5-42.5", "42.5-47.5", 
#'        "47.5-52.5", "52.5-57.5", "57.5-62.5", "62.5-67.5", "67.5-72.5", 
#'        ">72.5" mph (miles/h).
#' @template as_list
#' 
#' @return List. Emission factors in units 'g/km' by speed and model_year.
#' 
#' @details 
#' Users can view the pre-processed database in `data(ef_usa_moves_db)` function.
#' 
#' @family Emission factor model
#' 
#' @examples
#' df <- ef_usa_moves(
#'          pollutant = c("CO","PM10"),
#'          model_year = 2015,
#'          speed = units::set_units(10:100,"km/h"),
#'          reference_year = 2016,
#'          fuel = "D",
#'          as_list = TRUE
#'         )
#' @export
ef_usa_moves <- function(pollutant, model_year, reference_year = 2020, speed, fuel = 'D', as_list = TRUE){
  call <- rlang::current_env()  # header for conditions raised inside closures
  
  # use specific name-----
  tmp_fuel <- fuel
  tmp_pollutant <- pollutant
  tmp_model_year <- model_year
  tmp_reference_year <- reference_year
  utils::data(ef_usa_moves_db)
  temp_ef <- ef_usa_moves_db
  
  # Checkings -----
  # pollutant
  assert_vector(pollutant,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(pollutant,any.missing = FALSE,min.len = 1)
  for(i in pollutant) assert_choice(i,unique(ef_usa_moves_db$pollutant),null.ok = FALSE, .var.name = "pollutant")
  
  # reference_year
  assert_vector(reference_year,any.missing = FALSE,len = 1,null.ok = FALSE)
  assert_numeric(reference_year,lower = 2010,upper = 2020,len = 1,any.missing = FALSE)
  
  # fuel
  assert_vector(fuel,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(fuel,any.missing = FALSE,min.len = 1)
  for(i in unique(fuel)) assert_choice(i,c("CNG","D","G"),null.ok = FALSE, .var.name = "fuel")

  # model_year
  assert_vector(model_year,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(model_year,lower = 1989,upper = 2022,min.len = 1,any.missing = FALSE)
  
  # speed
  assert_vector(speed,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(speed,lower = 1,upper = 120.7)
  assert_class(speed,"units")
  
  # pre-filter in usa data----
  temp_moves <- temp_ef[reference_year %in% as.character(unique(tmp_reference_year)) &
                          fuel_type  %in% unique(tmp_fuel) &
                          pollutant %in% unique(tmp_pollutant) & 
                          model_year %in% unique(tmp_model_year), ]
  
  tmp_speed <- as.numeric(speed)
  
  # fuel
  if(length(tmp_model_year) != length(tmp_fuel) && length(tmp_fuel) == 1){
    tmp_fuel <- rep(tmp_fuel,length(tmp_model_year))
  }
  # model_year
  if(length(tmp_model_year) != length(tmp_fuel) && length(tmp_model_year) == 1){
    tmp_model_year <- rep(tmp_model_year,length(tmp_fuel))
  }
  
  # Filter by pollutant and model_year-----
  
  ef_pol <- lapply(pollutant, function(i){   # i = pollutant[1]
    
    temp_ef0 <- sapply(seq_along(tmp_model_year), function(j){   # j = 1
      # Filter Model Year & Pollutant & Fuel
      temp_moves2 <- data.table::copy(temp_moves)[pollutant %in% i & 
                                                    model_year %in% tmp_model_year[j] & 
                                                    fuel %in% tmp_fuel[j], ]
      # check condition
      if(dim(temp_moves2)[1] == 0){
        cli::cli_abort(c("No available emission factor for this combination of parameters:"
                         , "*" = "pollutant: {.val {i}}"
                         , "*" = "model_year: {.val {tmp_model_year[j]}}"
                         , "*" = "fuel: {.val {tmp_fuel[j]}}"
                         , "i" = "Check {.code data(ef_usa_emfac_db)} for available data.")
                       , class = c("gtfs2emis_missing_ef", "gtfs2emis_error")
                       , call = call)
      }
      return(temp_moves2[, ef])
    }) 
    temp_ef0 <- data.table::as.data.table(temp_ef0)
    names(temp_ef0) <- paste(i, as.character(tmp_model_year),tmp_fuel,sep = "_")
    return(temp_ef0)
  }) 
  
  # aggregate EF-----
  ef_final <- do.call(cbind, ef_pol)
  
  # Filter Speed based on emission factor data.table speed interval-----------
  tmp_speed2 <- rep(NA, length(tmp_speed))
  
  # data.table with upper_limit info
  tmp_limit <-  unique(temp_moves$upper_speed_interval) 
  tmp_limit <-  sort(as.numeric(tmp_limit),decreasing = TRUE)
  
  temp_order_dt <- data.table::data.table(
    "limit" = tmp_limit
    ,"id" = data.table::uniqueN(temp_moves$upper_speed_interval):1)
  
  for(t in 1:nrow(temp_order_dt)){ # t = 10
    tmp_speed2[tmp_speed <= temp_order_dt$limit[t]] <- temp_order_dt$id[t]
  }
  
  # case of speed lower than upper_limit_speed
  tmp_speed2[tmp_speed2==0] <- 1
  
  ef_final <- ef_final[tmp_speed2,]
  
  # add units
  ef_final <- ef_final[, lapply(.SD, units::set_units, "g/km")]
  
  # export-----
  
  # as.list
  if(as_list == TRUE){
    ef_final <- list("pollutant" = pollutant,
                     "model_year" = model_year,
                     "veh_type" = rep("BUS_URBAN_D",length(model_year)),
                     "fuel" = tmp_fuel,
                     "EF" = ef_final,
                     "process" = "hot_exhaust")
  }
  return(ef_final)
}

