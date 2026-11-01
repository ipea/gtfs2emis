#' @title 
#' Spatial aggregation of emission estimates into a grid
#'
#' @description 
#' Aggregate emissions proportionally in an sf polygon grid, by performing an 
#' intersection operation between emissions data in `sf linestring` format and 
#' the input grid cells. User can also aggregate the emissions in the grid 
#' by time of the day.
#'
#' @param emi_list list. A list containing the data of emissions 'emi' 
#'        ("data.frame" class) and the transport model 'tp_model' ("sf" 
#'        "data.frame" classes). 
#' @param grid Sf polygon. Grid cell data to allocate emissions.
#' @param time_resolution character. Time resolution in which the emissions is
#'        aggregated. Options are 'hour', 'minute', or 'day (Default).
#' @param quiet logical. User can print the total emissions before and after the
#'        intersection operation in order to check if the gridded emissions were 
#'        estimated correctly. Default is 'TRUE'.
#' @param aggregate logical. Aggregate emissions by pollutant. Default is `FALSE`.
#' 
#' @return An `"sf" "data.frame"` object with emissions estimates per grid cell.
#' 
#' @family emission analysis
#' 
#' @examples
#' \donttest{
#' if (requireNamespace("gtfstools", quietly=TRUE)) {
#' library(sf)
#' 
#' # read GTFS
#' gtfs_file <- system.file("extdata/bra_cur_gtfs.zip", package = "gtfs2emis")
#' gtfs <- gtfstools::read_gtfs(gtfs_file) 
#' 
#' # keep a single trip_id to speed up this example
#' gtfs_small <- gtfstools::filter_by_trip_id(gtfs, trip_id ="4451136")
#'   
#' # run transport model
#' tp_model <- transport_model(gtfs_data = gtfs_small,
#'                             spatial_resolution = 100,
#'                             parallel = FALSE)
#'
#' # Fleet data, using Brazilian emission model and fleet
#' fleet_data_ef_cetesb <- data.frame(veh_type = "BUS_URBAN_D",
#'                                    model_year = 2010:2019,
#'                                    fuel = "D",
#'                                    fleet_composition = rep(0.1,10)
#'                                    )
#' # Emission model
#' emi_list <- emission_model(
#'                 tp_model = tp_model,
#'                 ef_model = "ef_brazil_cetesb",
#'                 fleet_data = fleet_data_ef_cetesb,
#'                 pollutant = c("CO","PM10","CO2","CH4","NOx")
#'                 )
#'
#' # create spatial grid
#' grid <- sf::st_make_grid(
#'   x = sf::st_make_valid(emi_list$tp_model)
#'   , cellsize = 0.25 / 200
#'   , crs= 4326
#'   , what = "polygons"
#'   , square = FALSE
#'   )
#' 
#' emi_grid <- emis_grid( emi_list,grid,'day')
#' 
#' plot(grid)
#' plot(emi_grid["PM10_2010"],add = TRUE)
#' plot(st_geometry(emi_list$tp_model), add = TRUE,col = "black")
#' }
#' }
#' @export
emis_grid <- function(emi_list, grid, time_resolution = 'day',quiet = TRUE,aggregate = FALSE){
  
  # 1) Check -----
  assert_list(emi_list, null.ok = FALSE)
  assert_checks(
    checkmate::check_choice("emi",names(emi_list))
    , checkmate::check_choice("tp_model",names(emi_list))
    , combine = "and", .var.name = "emi_list"
  )
  assert_class(emi_list$tp_model, classes = c("sf", "data.frame"))
  assert_checks(
    checkmate::check_vector(time_resolution,len = 1, null.ok = FALSE)
    ,checkmate::check_string(time_resolution, null.ok = FALSE)
    ,checkmate::check_choice(time_resolution,c('day','minute','hour'),null.ok = FALSE)
    ,combine = "and", .var.name = "time_resolution"
  )
  assert_checks(
    checkmate::check_class(grid, "sf")
    , checkmate::check_class(grid, "sfc")
    , combine = "or", .var.name = "grid"
  )
  assert_logical(quiet)
  assert_logical(aggregate)
  
  if(sf::st_crs(grid) != sf::st_crs(emi_list$tp_model)){
    cli::cli_abort(c("{.arg emi_list$tp_model} and {.arg grid} must have the same projection."
                     , "i" = "Check {.fn sf::st_crs}.")
                   , class = "gtfs2emis_error")
  }
  if(time_resolution != "day"){
    assert_checks(
      checkmate::check_choice("timestamp", names(emi_list$tp_model))
      , checkmate::check_class(emi_list$tp_model$timestamp,"ITime",null.ok = FALSE)
      , checkmate::check_posixct(emi_list$tp_model$timestamp,null.ok = FALSE)
      , combine = "or", .var.name = "emi_list$tp_model$timestamp"
    )
    if(sum(is.na(emi_list$tp_model$timestamp))>0){
      cli::cli_abort("{.field timestamp} in {.arg emi_list$tp_model} has {.val NA} values."
                     , class = "gtfs2emis_error")
    }
  }
  
  # convert 'geom' to "sf" "data.fram" if a "sfc" was given
  # and add 'ID' info
  if (inherits(grid,"sfc")) {
    grid <-sf::st_sf(data = data.frame(id = 1:length(grid),grid))
  }else{
    grid$id <- 1:(dim(grid)[1])
  }
  
  # aggregate condition
  if(aggregate){
    emi_list$road_segment <- 1:nrow(emi_list$tp_model)
    tmp_emi <- emis_summary(emi_list
                 ,segment_vars = "road_segment")
    tmp_emi <- data.table::dcast(tmp_emi
                                 ,formula = road_segment ~ pollutant + process 
                                 ,value.var = "emi"
                                 ,fun.aggregate = sum)
    tmp_emi[,road_segment := NULL]
    emi_list$emi <- tmp_emi
  }
  # 2) Cbind and rename ----- 
  tmp_tp_emi <- cbind(emi_list$tp_model, emi_list$emi)
  
  data.table::setDT(tmp_tp_emi)
  name_emi_old <- names(emi_list$emi)
  name_emi_new <- sprintf("%s_%s"
                          ,name_emi_old
                          ,seq_along(name_emi_old))
  data.table::setnames(tmp_tp_emi
                       ,old = name_emi_old
                       ,new = name_emi_new)
  
  # 3) Check units ----
  # Working files
  netdata <- data.table::copy(data.table::as.data.table(tmp_tp_emi))
  net <- sf::st_as_sf(data.table::setDF(tmp_tp_emi))
  
  emi_units <- c()
  for(i in seq_along(name_emi_new)){ # i = 1
    if(is(netdata[, .SD, .SDcols = (name_emi_new[i])][[1]], "units")){
      # retrieve units
      emi_units[i] <- units::deparse_unit(
        netdata[, .SD
                , .SDcols = (name_emi_new[i])][[1]]
      )
    }else{
      emi_units[i] <- NA
      
    }
  }
  # numeric
  netdata[, (name_emi_new) := lapply(.SD, as.numeric), .SDcols = name_emi_new]
  
  # 4) Display emissions BEFORE  -----
  #
  # objective: user verification purposes, they can check if
  # the intersection operation into grid are displaying the total 
  # emissions correctly
  #
  print_emissions <- function(emissions,name_old,name_new,emi_units){
    sapply(seq_along(name_emi_new), function(j){# j = 1
      sumofstreets <- emissions[
        , lapply(.SD, sum, na.rm = TRUE)
        , .SDcols = name_new[j]]
      sumofstreets <- as.numeric(sumofstreets)
      
      # printing nicely
      nzeros_after_decimal <- attr(regexpr("(?<=\\.)0+"
                                           , sumofstreets
                                           , perl = TRUE)
                                   , "match.length")
      round_sum <- ifelse(nzeros_after_decimal>0
                          ,round(sumofstreets,nzeros_after_decimal + 3)
                          ,round(sumofstreets,2))
      cli::cli_inform("{name_old[j]} = {round_sum} {emi_units[j]}")
    })
    return(NULL)
  }
  
  if(!quiet){
    cli::cli_inform("Sum of street emissions")
    print_emissions(netdata,name_emi_old,name_emi_new,emi_units)
  }
  
  # 5) Estimate emissions -------
  
  tmp_netdata <- data.table::copy(netdata)
  data.table::setDT(tmp_netdata)
  if(time_resolution != "day"){
    # 'hour' resolution
    if(time_resolution == "hour"){
      tmp_netdata[, "timestamp" := data.table::hour(timestamp)]
    }
    # 'minute' resolution
    if(time_resolution == "minute"){
      
      tmp_netdata[
        , "timestamp" := sprintf("%s:%s"
                                 ,data.table::hour(timestamp) 
                                 ,data.table::minute(timestamp))]
    }
    
    # 'time_column' scenario 
    tmp_netdata <- tmp_netdata[
      , lapply(.SD, sum, na.rm = TRUE)
      , .SDcols = name_emi_new
      , by = .(timestamp
               , shape_id
               , stop_sequence
               , from_stop_id
               , to_stop_id)]
    
  }else{
    
    # No 'time_column' scenario 
    tmp_netdata <- tmp_netdata[
      , lapply(.SD, sum, na.rm = TRUE)
      , .SDcols = name_emi_new
      , by = .(shape_id
               , stop_sequence
               , from_stop_id
               , to_stop_id)]
    
  }
  
  # Add geometry into 'netdata' 
  
  tmp_netdata[netdata
              ,on = c("shape_id"
                      ,"stop_sequence"
                      ,"from_stop_id"
                      ,"to_stop_id")
              ,geometry := i.geometry]
  
  # 'tmp_netdata' to net
  net <- sf::st_as_sf(data.table::setDF(tmp_netdata))
  
  # 6) Reduce grid size  -----
  # Keep only polygons that intersect with lines
  
  intersect_index <- sf::st_intersects(grid, net,sparse = FALSE)
  intersect_index <- rowSums(intersect_index)
  intersect_index <- which(intersect_index>0)
  grid <- subset(grid, id %in% intersect_index)
  net$temp_lkm <- sf::st_length(net)
  
  # 7) Intersection -----
  netg <- suppressMessages(suppressWarnings(
    sf::st_intersection(net, grid)))
  
  netg$lkm_inter <- sf::st_length(netg)
  
  # ratio of 'lkm'
  data.table::setDT(netg)
  netg[, ratio := lkm_inter / temp_lkm]
  
  # adjust emissions by ratio
  for (i in name_emi_new) netg[, (i) := get(i) * ratio]
  
  # 8) Aggregate by TIME-------------------
  
  if(time_resolution != "day"){
    
    # time_resolution
    netg <- netg[
      , lapply(.SD, sum, na.rm = TRUE)
      ,.SDcols = name_emi_new
      ,by = .(timestamp, id)]
    
  }else{
    
    # aggregation of emissions without specified time
    netg <- netg[
      , lapply(.SD, sum, na.rm = TRUE)
      , by = .(id)
      ,.SDcols = name_emi_new]
    
  }
  
  temp_output <- netg[data.table::setDT(grid)
                      ,on = "id"]
  
  # add units
  temp_output[
    , (name_emi_new) := lapply(.SD, as.numeric)
    , .SDcols = name_emi_new
  ]
  for(k in seq_along(emi_units)){ # k = 1
    
    temp_output[
      , (name_emi_new[k]) := lapply(.SD, 
                                    units::as_units,
                                    emi_units[k])
      ,.SDcols = name_emi_new[k]]
    
  }
  

  # 9) Display emissions AFTER ----

  if(!quiet){
    cli::cli_inform("Sum of gridded emissions")
    print_emissions(temp_output,name_emi_old,name_emi_new,emi_units)
  }
  
  # 10) Rename and export ----
  temp_output$id <- NULL
  data.table::setnames(temp_output
                       ,old = name_emi_new
                       ,new = name_emi_old)
  
  temp_output <- sf::st_as_sf(temp_output)
  
  return(temp_output)
}
