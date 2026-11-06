#' @title 
#' Scale local emission factors in order to make emission estimates a function 
#' of speed.
#' 
#' @description 
#' Scale emission factors to account for vehicle speed based on values from the 
#' emission factor model by the European Environment Agency (EMEP/EEA). Emission 
#' factor estimates are expressed in units 'g/km'.
#' 
#' @param ef_local data.frame or a list containing the emission factors data.frame.
#'        Local emission factors, in units 'g/km'.
#' @param speed units. Speed in 'km/h'.
#' @param veh_type character. Bus type, classified as "Ubus Midi <=15 t",
#'       "Ubus Std 15 - 18 t",  "Ubus Artic >18 t", "Coaches Std <=18 t", or 
#'       "Coaches Artic >18 t".
#' @param euro character. Euro period of vehicle, classified in "Conventional", 
#'        "I", "II", "III", "IV", "V", "VI", and "EEV".
#' @param pollutant character. Pollutant: "FC", "CO2", "CO", "NOx", "VOC", 
#'        "PM10", "EC", "CH4", "NH3", "N2O", "FC" (fuel consumption). 
#' @param fuel character. Fuel type, classified in "D" (Diesel), "DHD" (Diesel 
#'        Hybrid ~ Diesel), "DHE" (Diesel Hybrid ~ Electricity), "CNG" 
#'        (Compressed Natural Gas), "BD" (Biodiesel). Default is "D". 
#' @param tech character. After treatment technology, classified in "SCR" 
#'        (Selective Catalytic Reduction), "EGR" (Exhaust Gas Recirculation), 
#'        and "DPF+SCR" (Diesel Particulate Filter + SCR, for Euro VI). Default 
#'        is "SCR" for "IV" and "V".
#' @param SDC numeric. Average speed of urban driving condition in 'km/h'. 
#'        Default is 19 km/h,  which is the average speed adopted in EMEP/EEA
#'        report.
#' @param slope numeric. Slope gradient, categorized in -0.06, -0.04, -0.02, 
#'        0.00, 0.02, 0.04 and 0.06. Negative gradients means downhills and 
#'        positive uphills. Default is 0.0. Either one value or one per `speed`.
#' @param load numeric. Passenger load ratio, classified in 0.0, 0.5 and 1.0.
#'        Default is 0.5. `slope` and `load` change only the speed-dependent
#'        EMEP/EEA factor; the reference at `SDC` always uses slope 0 and load 0.5.
#' @param fcorr numeric. Correction based on fuel composition. The length must 
#'        be one per each euro standards. Default is 1.0.
#' 
#' @return list. Emission factors in units 'g/km'.
#' @details 
#' 
#' The scaled emission factor is related to speed by the expression
#' 
#'  EF_scaled (V) = EF_local * ( EF(V) / EF(SDC)), 
#'  
#'  where EF_scaled(V) is the scaled emission factors for each street link, 
#'  EF_local is the local emission factor, EF(V) and EF(SDC) are the EMEP/EEA
#'  emission factor the speed of V and the average urban driving speed 'SDC', respectively.
#'
#' Please note that the function reads the vector arguments in the same order 
#' as informed by the user. For instance, if the pollutant input is `c("CO","PM10")`
#' input in the local emission factor function, the order needs to be the same for the
#' pollutant in the `ef_scaled_euro` function. 
#' 
#' In the case of vehicle type, which generally changes according to the emission 
#' factor source, the input argument in the `ef_scaled_euro` needs to be consistent
#' with the order adopted in the local emission factor function.
#' 
#' For example, if the vector of local vehicle type is 
#'  `c("BUS_URBAN_D","BUS_MICRO_D")`, the related vector for EMEP/EEA model needs
#'  to be `c("Ubus Std 15 - 18 t","Ubus Midi <=15 t")`. The same approach applies for
#'  other input arguments. See more in the examples. 
#' 
#' @family Emission factor model
#' 
#' @examples
#' temp_ef_br <- ef_brazil_cetesb(
#'                     pollutant = c("CO","PM10","CO2","CH4","NOx"),
#'                     veh_type = c("BUS_URBAN_D","BUS_MICRO_D"),
#'                     model_year = c(2015,2015),
#'                     as_list = TRUE
#'                     )
#' 
#' temp_ef_scaled <- ef_scaled_euro(
#'                     ef_local = temp_ef_br,
#'                     speed = units::set_units(1:100,"km/h"),
#'                     veh_type = c("Ubus Std 15 - 18 t","Ubus Midi <=15 t"),
#'                     euro = c("IV","IV"),
#'                     fuel = c("D","D"),
#'                     tech = c("SCR","SCR"),
#'                     pollutant = c("CO","PM10","CO2","CH4","NOx")
#'                     )
#' @export
ef_scaled_euro <- function(ef_local, speed, veh_type, euro, pollutant, fuel = "D", 
                           tech = "SCR", SDC = 19, slope = 0.0, 
                           load = 0.5, fcorr = 1){
  call <- rlang::current_env()  # header for conditions raised inside closures

  # check inputs ----
  # euro vector
  utils::data('ef_europe_emep_db') 
  temp_ef <- ef_europe_emep_db
  
  # ef_local
  if(inherits(ef_local,what = "list")) {
    assert_choice("EF", names(ef_local), .var.name = "ef_local")
    assert_checks(
      checkmate::check_class(ef_local$EF, "data.frame")
      , checkmate::check_class(ef_local$EF, "data.table")
      , checkmate::check_class(ef_local$EF, "units")
      , combine = "or", .var.name = "ef_local$EF"
    )
  }
  assert_checks(
    checkmate::check_class(ef_local, "data.frame")
    , checkmate::check_class(ef_local, "data.table")
    , checkmate::check_list(ef_local)
    , checkmate::check_class(ef_local, "units")
    , combine = "or", .var.name = "ef_local"
  )

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
  # pollutant
  assert_vector(pollutant,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(pollutant,any.missing = FALSE,min.len = 1)
  for(i in pollutant) assert_choice(i,unique(temp_ef$Pol),null.ok = FALSE, .var.name = "pollutant")
  # fuel
  assert_vector(fuel,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(fuel,any.missing = FALSE,min.len = 1)
  for(i in fuel) assert_choice(i,unique(temp_ef$Fuel),null.ok = FALSE, .var.name = "fuel")
  # technology
  assert_vector(tech,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_character(tech,any.missing = FALSE,min.len = 1)
  for(i in tech) assert_choice(i,unique(temp_ef$Technology),null.ok = FALSE, .var.name = "tech")
  
  #
  # check dimensions
  #
  temp_ef$Pol
  if (is(ef_local, "list")) {
    ef_local <- ef_local$EF
  }
  if (length(veh_type) == 1) {
    veh_type <- rep(veh_type, length(euro))
  }
  if (length(veh_type) != length(euro)) {
    cli::cli_abort("{.arg euro} and {.arg veh_type} must have the same length."
                   , class = "gtfs2emis_error")
  }
  if (length(fuel) == 1) {
    fuel <- rep(fuel,length(euro))
  }
  if (length(fuel) != length(euro)) {
    cli::cli_abort("{.arg fuel} and {.arg veh_type} must have the same length."
                   , class = "gtfs2emis_error")
  }
  
  #
  # check units
  #
  
  lapply(seq_along(ef_local), function(i){ # i = 1
    if (!is(ef_local, "units")) {
      cli::cli_abort("{.arg ef_local} must have units {.val g/km}."
                     , class = "gtfs2emis_error", call = call)
    }
    if(units(ef_local[[i]])$numerator != "g" | units(ef_local[[i]])$denominator != "km"){
      cli::cli_abort("{.arg ef_local} must have units {.val g/km}."
                     , class = "gtfs2emis_error", call = call)
    }
  })
  
  #
  # ef_europe with SDC (urban driving speed condition)
  #
  
  # local factors (e.g. CETESB) stand for flat roads at reference load, so the
  # reference is taken at slope 0 / load 0.5; a per-slope reference would cancel
  # the gradient effect
  ef_sdc <- ef_europe_emep(speed = units::set_units(SDC, "km/h"),
                      veh_type = veh_type,
                      euro = euro,
                      pollutant = pollutant,
                      fuel = fuel,
                      tech = tech,
                      slope = 0,
                      load = 0.5,
                      fcorr = fcorr,
                      as_list = FALSE)
  
  # ef_europe(speed = units::set_units(rnorm(100,50,5),"km/h"),
  #                 veh_type = c("Urban Buses Standard 15 - 18 t","Urban Buses Articulated >18 t"),
  #                 euro = c("IV","V"),
  #                 pollutant = c("CO2","NOx"),
  #                 fuel = "Diesel" ,
  #                 tech =  c("SCR","EGR"),
  #                 slope = 0.0,
  #                 load = 0.5,
  #                 fcorr = 1,
  #                 as_list = TRUE)
  # adjustment factor
  k <- as.numeric(ef_local)/as.numeric(ef_sdc) 
  
  # ef europe speed
  ef_speed <- ef_europe_emep(speed = speed, 
                        veh_type = veh_type,
                        fuel = fuel,
                        euro = euro,
                        slope = slope,
                        load = load,
                        tech = tech, 
                        fcorr = fcorr,
                        pollutant = pollutant,
                        as_list = TRUE)
  ef_speed$EF <- as.matrix(ef_speed$EF)
  
  #
  # ef_scaled
  #
  
  ef_scaled <- sapply(seq_along(k),function(i){ef_speed$EF[,i] * k[i]})
  if(length(speed) == 1){
    ef_scaled <- t(as.matrix(ef_scaled))
  }
  
  # to units
  ef_scaled <- units::set_units(ef_scaled, 'g/km')
  ef_scaled <- data.table::as.data.table(ef_scaled)
  colnames(ef_scaled) <- colnames(ef_speed$EF)
  # add back to list
  ef_speed$EF <- ef_scaled
  
  return(ef_speed)
}
