#' @title 
#' Running exhaust emissions factors for buses from United States (EMFAC2017 model)
#' 
#' @description 
#' Returns a vector or data.frame of emission factors for buses based on the
#' [California EMission Factor model (EMFAC2017)](https://arb.ca.gov/emfac/). 
#' The model considers emission factors (EF) of urban buses in California 
#' (United States), considering different pollutants, years of reference, model 
#' year, fuel, speed ranges, type of regions, model version, and type of season. 
#' The gtfs2emis package currently supports EF only for "Statewide" region type, 
#' and "Annual" season.  Specific data of these variables can be download at 
#' <<https://arb.ca.gov/emfac/emissions-inventory>>.
#'
#' @param pollutant character. Pollutants: "CH4" (Methane), "CO" (Carbon 
#'        Monoxide), "CO2" (Carbon Dioxide), "N2O" (Nitrous Oxide), "NOx" 
#'        (Oxides of Nitrogen), "PM10" (Primary Exhaust PM10 - Total), "PM25" 
#'        (Primary Exhaust PM2.5 - Total), "SOX" (Oxides of Sulfur), "TOG" 
#'        (Total Organic Gases), "ROG"  (Reactive Organic Gases).
#' @template reference_year
#' @template fuel
#' @param model_year Numeric; Model year of vehicle.
#' @param speed Units. Speed in 'km/h'; Emission factor are returned in speed 
#'        intervals: "5-10", "10-15", "15-20", "20-25", "25-30", "30-35", 
#'        "35-40", "40-45", "45-50", "50-55", "55-60", "60-65", "65-70", "70-75", 
#'        "75-80", "80-85", "85-90", ">90" mph (miles/h).
#' @template as_list
#' 
#' @return List or data.table. Emission factors in units 'g/km' by speed and model_year.
#' @source \url{https://arb.ca.gov/emfac/}
#' 
#' @family Emission factor model
#' 
#' @examples
#' df <- ef_usa_emfac(
#'         pollutant = c("CO","PM10"),
#'         reference_year = 2019,
#'         model_year = 2015,
#'         speed = units::set_units(10:100,"km/h"),
#'         fuel = "D",
#'         as_list = TRUE
#'         )
#' @export
ef_usa_emfac <- function(pollutant, reference_year = 2020, fuel = 'D'
                         , model_year, speed, as_list = TRUE){
  call <- rlang::current_env()  # header for conditions raised inside closures
  
  # Use specific name-----
  tmp_fuel <- fuel
  tmp_reference_year <- reference_year
  tmp_pollutant <- pollutant
  tmp_model_year <- model_year
  utils::data('ef_usa_emfac_db') 
  
  # check inputs ----
  # pollutant
  assert_vector(pollutant,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(pollutant,any.missing = FALSE,min.len = 1)
  for(i in pollutant) assert_choice(i,unique(ef_usa_emfac_db$pollutant),null.ok = FALSE, .var.name = "pollutant")
  
  # reference_year
  assert_vector(reference_year,any.missing = FALSE,len = 1,null.ok = FALSE)
  assert_numeric(reference_year,lower = 2010,upper = 2020,len = 1,any.missing = FALSE)
  
  # fuel
  assert_vector(fuel,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(fuel,any.missing = FALSE,min.len = 1)
  for(i in fuel) assert_choice(i,unique(ef_usa_emfac_db$fuel),null.ok = FALSE, .var.name = "fuel")
  
  # model_year
  assert_vector(model_year,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(model_year,lower = 1982,upper = 2020,min.len = 1,any.missing = FALSE)
  # speed
  assert_vector(speed,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(speed,lower = 1,upper = 113)
  assert_class(speed,"units")
  
    # Pre-filter in usa data----
  temp_emfac <- ef_usa_emfac_db[reference_year %in% as.character(unique(tmp_reference_year)) &
                                  fuel %in% unique(tmp_fuel) &
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
      temp_emfac2 <- data.table::copy(temp_emfac)[pollutant %in% i & 
                                                    model_year %in% tmp_model_year[j] & 
                                                    fuel %in% tmp_fuel[j], ]
      # check condition
      if(dim(temp_emfac2)[1] == 0){
        cli::cli_abort(c("No available emission factor for this combination of parameters:"
                         , "*" = "pollutant: {.val {i}}"
                         , "*" = "model_year: {.val {tmp_model_year[j]}}"
                         , "*" = "fuel: {.val {tmp_fuel[j]}}"
                         , "i" = "Check {.code data(ef_usa_emfac_db)} for available data.")
                       , class = c("gtfs2emis_missing_ef", "gtfs2emis_error")
                       , call = call)
      }
      return(temp_emfac2[, ef])
    }) 
    temp_ef0 <- data.table::as.data.table(temp_ef0)
    names(temp_ef0) <- paste(i, as.character(tmp_model_year),tmp_fuel,sep = "_")
    return(temp_ef0)
  }) 
  
  # Aggregate EF-----
  ef_final <- do.call(cbind, ef_pol)
  
  # Filter Speed based on emission factor data.table speed interval-----------
  tmp_speed2 <- rep(NA, length(tmp_speed))
  
  # data.table with upper_limit info
  temp_order_dt <- data.table::data.table(
    "limit" =  
      sort(as.numeric(unique(
        temp_emfac$upper_speed_interval)
      ), decreasing = TRUE)
    ,"id" = data.table::uniqueN(temp_emfac$upper_speed_interval):1
  )
  
  for(t in 1:nrow(temp_order_dt)){ # t = 10
    tmp_speed2[tmp_speed <= temp_order_dt$limit[t]] <- temp_order_dt$id[t]
  }
  
  # case of speed lower than upper_limit_speed
  tmp_speed2[tmp_speed2 == 0] <- 1
  
  ef_final <- ef_final[tmp_speed2,]
  
  # add units
  ef_final <- ef_final[, lapply(.SD, units::set_units, "g/km")]
  
  # export-----
  
  # as.list
  if(as_list == TRUE){
    ef_final <- list(
      "pollutant" = pollutant,
      "model_year" = model_year,
      "veh_type" = rep("BUS_URBAN_D",length(model_year)),
      "fuel" = tmp_fuel,
      "EF" = ef_final,
      "process" = "hot_exhaust"
    )
  }
  return(ef_final)
}

