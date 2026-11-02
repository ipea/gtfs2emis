#' @title 
#' Summarize emissions estimates
#'
#' @description 
#' Summarize emissions estimates, aggregating emissions by pollutant, time of 
#' the day, vehicle.
#'
#' @param emi_list list. Emission or emission factor list.
#' @param by character. Emissions can be aggregated by 'time', 'vehicle', or 
#'       simply 'pollutant' (Default). 
#' @param veh_vars character. data.frame names of 'emi_list' attributed to 
#'        vehicle characteristics. Default is 'veh_type'.
#' @param segment_vars character. data.frame names of 'emi_list' object 
#'        attributed to the road segments. Default is NULL.
#' @param process_vars character. data.frame names of 'emi_list' object 
#'        attributed to the emission processes. Default is 'process'.
#' @return `data.table` with pollutants units ('g') aggregated by pollutant, 
#'          time, or vehicle type.
#' 
#' @family emission analysis
#' 
#' @examples
#' \donttest{
#' if (requireNamespace("gtfstools", quietly=TRUE)) {
#' 
#' # read GTFS
#' gtfs_file <- system.file("extdata/irl_dub_gtfs.zip", package = "gtfs2emis")
#' gtfs <- gtfstools::read_gtfs(gtfs_file)
#' 
#' # Keep a single trip
#' gtfs <- gtfstools::filter_by_trip_id(gtfs
#'                                      , trip_id = c('238.2.60-118-b12-1.59.I'
#'                                                    ,"7081.2.60-X27-b12-1.106.I"))
#' # Transport model
#' tp_model <- transport_model(gtfs_data = gtfs,
#'                             spatial_resolution = 100,
#'                             parallel = FALSE)
#' 
#' # fleet data
#' fleet_df <- read.csv(system.file("extdata/irl_dub_fleet.txt"
#'                                  , package = "gtfs2emis"))
#' # emission model
#' emi_list <- emission_model(tp_model = tp_model
#'                            , ef_model = "ef_europe_emep"
#'                            , fleet_data = fleet_df
#'                            , pollutant = c("CO2","PM10"))
#'
#' # Aggregate total emissions by 'pollutant'
#' emis_summary(emi_list) 
#' 
#' # by vehicle type
#' emis_summary(emi_list, by = "vehicle")
#'              
#' emis_summary(emi_list
#'              , by = "vehicle"
#'              , veh_vars = c("euro"))
#'
#' emis_summary(emi_list
#'              , by = "vehicle"
#'              , veh_vars = c("fuel"))
#'
#' emis_summary(emi_list
#'              , by = "vehicle"
#'              , veh_vars = c("veh_type","euro","tech","fuel"))
#'              
#' # by time of the day
#' emis_summary(emi_list
#'              , by = "time"
#'              , segment_vars = "slope") 
#' }
#' }
#' @export
emis_summary <- function(emi_list, 
                         by = "pollutant", 
                         veh_vars = "veh_type", 
                         segment_vars = NULL,
                         process_vars = "process"){
  call <- rlang::current_env()  # header for conditions raised inside closures
  
  # A) Checking inputs -----
  
  assert_list(emi_list, null.ok = FALSE)
  assert_vector(by, len = 1,null.ok = FALSE)
  assert_string(by, null.ok = FALSE)
  assert_vector(segment_vars, len = 1, null.ok = TRUE)
  assert_string(segment_vars, null.ok = TRUE)
  
  assert_choice("emi",names(emi_list),null.ok = FALSE, .var.name = "emi_list")
  assert_choice("pollutant",names(emi_list),null.ok = FALSE, .var.name = "emi_list")
  assert_choice(by,c("time","vehicle","pollutant"),null.ok = FALSE)
  assert_choice(segment_vars,names(emi_list),null.ok = TRUE)
  
  if(by == "time"){
    segment_vars = "tp_model"
    assert_choice(segment_vars,names(emi_list),null.ok = FALSE)
    assert_choice("timestamp",names(emi_list[[segment_vars]]), .var.name = "emi_list$tp_model")
    if(length(emi_list[[segment_vars]][["timestamp"]]) != nrow(emi_list[["emi"]])){
      cli::cli_abort("{.arg emi_list$emi} columns must have the same length as {.field timestamp}."
                     , class = "gtfs2emis_error")
    }
  }
  if(by == "vehicle"){
    assert_vector(veh_vars,min.len = 1,unique = TRUE, null.ok = FALSE)
    for(i in veh_vars) assert_choice(i,names(emi_list),null.ok = FALSE, .var.name = "veh_vars")
  }
  
  #
  # check 'emi_vars' units-----
  #
  
  lapply(seq_along(emi_list[["emi"]]),function(i){ 
    assert_class(emi_list[["emi"]][[i]],"units", .var.name = "emi_list$emi", call = call)
    if(units::deparse_unit(emi_list[["emi"]][[i]]) != "g" & 
       units::deparse_unit(emi_list[["emi"]][[i]]) != "kg"){
      cli::cli_abort("{.arg emi_list$emi} must have units {.val g} or {.val kg}."
                     , class = "gtfs2emis_error", call = call)
    }
  })
  
  #  aggregate --------
  
  # variables to use
  if(by == "time")  {
    my_var <- "timestamp_hour"
    emi_list[[my_var]] <- data.table::hour(
      emi_list[[segment_vars]][["timestamp"]]
    ) 
  }
  if(by == "vehicle")  {
    my_var <- veh_vars 
    segment_vars <- NULL
  }
  
  # to DT
  tmp_dt <- emis_to_dt(emi_list = emi_list
                       , emi_vars = "emi"
                       , veh_vars = veh_vars
                       , pol_vars = "pollutant"
                       , segment_vars =  if(by == "time"){my_var}else{segment_vars}
                       , process_vars = process_vars
  )
  
  
  # perform sum
  if(by == "pollutant"){
    if(!is.null(segment_vars)){
      tmp_dt <- tmp_dt[,lapply(.SD,sum,na.rm = TRUE)
                       ,by = c("pollutant",segment_vars,process_vars)
                       ,.SDcols = c("emi")]
      
    }else{
      tmp_dt <- tmp_dt[,lapply(.SD,sum,na.rm = TRUE)
                       ,by = c("pollutant",process_vars)
                       ,.SDcols = c("emi")]
    }
  }else{
    tmp_dt <- tmp_dt[,lapply(.SD,sum,na.rm = TRUE)
                     ,by = c(my_var,"pollutant",process_vars)
                     ,.SDcols = c("emi")]
    if(by == "time") data.table::setorderv(tmp_dt, my_var)
  }
  
  
  return(tmp_dt)
}
