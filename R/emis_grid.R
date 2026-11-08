#' @title 
#' Spatial aggregation of emission estimates into a grid
#'
#' @description 
#' Aggregate emissions proportionally in an sf polygon grid, by performing an 
#' intersection operation between emissions data in `sf linestring` format and 
#' the input grid cells. User can also aggregate the emissions in the grid 
#' by time of the day.
#'
#' @details
#' Emissions of each road segment are split between grid cells in proportion
#' to the length of the segment in each cell. With longitude/latitude data,
#' segments are cut by the cells with planar geometry (straight cell edges in
#' longitude/latitude, as drawn by [sf::st_make_grid()]), and lengths are
#' geodesic. Grids or segments that cross the antimeridian (±180°) are not
#' supported.
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
#'                             spatial_resolution = 100)
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
  # Working file: an alias of 'tmp_tp_emi', a new table made by cbind(). Its
  # columns are only replaced (step 5 overwrites 'timestamp' with the time
  # bin), never modified in place, so the caller's 'emi_list' is unchanged
  netdata <- tmp_tp_emi

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
      cli::cli_inform("{name_old[j]} = {round_sum} {if (is.na(emi_units[j])) '' else emi_units[j]}")
    })
    return(NULL)
  }
  
  if(!quiet){
    cli::cli_inform("Sum of street emissions")
    print_emissions(netdata,name_emi_old,name_emi_new,emi_units)
  }
  
  # 5) Estimate emissions -------
  
  seg_keys <- c("shape_id", "stop_sequence", "from_stop_id", "to_stop_id")
  by_vars <- seg_keys
  if(time_resolution != "day"){
    by_vars <- c("timestamp", seg_keys)
    # 'hour' resolution
    if(time_resolution == "hour"){
      netdata[, "timestamp" := data.table::hour(timestamp)]
    }
    # 'minute' resolution
    if(time_resolution == "minute"){
      
      netdata[
        , "timestamp" := sprintf("%02d:%02d"
                                 ,data.table::hour(timestamp) 
                                 ,data.table::minute(timestamp))]
    }
  }

  # emissions per segment (and time bin)
  emi_seg <- netdata[
    , lapply(.SD, sum, na.rm = TRUE)
    , .SDcols = name_emi_new
    , by = by_vars]

  # one geometry per segment: the time bins of a segment share it, so the
  # grid intersection is done once per segment, not once per time bin
  # (when a segment key repeats, the last geometry is kept)
  seg <- unique(netdata[, .SD, .SDcols = seg_keys])
  seg[netdata, on = seg_keys, geometry := i.geometry]
  data.table::set(seg, j = "seg_id", value = seq_len(nrow(seg)))
  data.table::set(emi_seg, j = "seg_id"
                  , value = seg[emi_seg, on = seg_keys, which = TRUE])

  # 'seg' to net
  net <- sf::st_as_sf(data.table::setDF(seg[, .SD, .SDcols = c("seg_id", "geometry")]))

  # segment lengths (geodesic for longitude/latitude data)
  net$temp_lkm <- sf::st_length(net)

  # cut segments into their straight edges (two points each): GEOS merges the
  # parts of a line that overlap (a route that doubles back on itself), which
  # would lose length; separate edges keep every part
  if(inherits(sf::st_geometry(net), "sfc_GEOMETRY")){  # mixed line types
    net <- sf::st_cast(net, "MULTILINESTRING")
  }
  xy <- sf::st_coordinates(net)
  part_cols <- grep("^L", colnames(xy))
  part_key <- do.call(paste, as.data.frame(xy[, part_cols, drop = FALSE]))
  edge_from <- which(part_key[-1] == part_key[-nrow(xy)])
  edge_wkt <- sprintf("LINESTRING (%.17g %.17g, %.17g %.17g)"
                      , xy[edge_from, "X"], xy[edge_from, "Y"]
                      , xy[edge_from + 1, "X"], xy[edge_from + 1, "Y"])
  edges <- sf::st_sf(seg_id = net$seg_id[xy[edge_from, max(part_cols)]]
                     , geometry = sf::st_as_sfc(edge_wkt, crs = sf::st_crs(net)))

  # with longitude/latitude data, cells are selected and cut with planar
  # (GEOS) geometry, which is much faster than spherical (s2) geometry and
  # follows grid edges drawn straight in longitude/latitude, as
  # sf::st_make_grid() draws them; lengths stay geodesic
  planar <- isTRUE(sf::st_is_longlat(grid))
  if(planar){
    old_s2 <- suppressMessages(sf::sf_use_s2(FALSE))
    on.exit(suppressMessages(sf::sf_use_s2(old_s2)), add = TRUE)  # if an error occurs
  }

  # 6) Reduce grid size  -----
  # Keep only polygons that intersect with lines

  # sparse index: a dense grid x segment matrix can take several GB
  intersect_index <- lengths(suppressMessages(sf::st_intersects(grid, edges)))
  intersect_index <- which(intersect_index>0)
  grid <- subset(grid, id %in% intersect_index)

  # 7) Intersection -----
  netg <- suppressMessages(suppressWarnings(
    sf::st_intersection(edges, grid[, "id"])))
  if(planar) suppressMessages(sf::sf_use_s2(old_s2))

  netg$lkm_inter <- sf::st_length(netg)

  # ratio of 'lkm': length of the segment in each cell / segment length
  netg <- data.table::data.table(
    seg_id = netg$seg_id
    , id = netg$id
    , ratio = as.numeric(netg$lkm_inter) / as.numeric(net$temp_lkm[netg$seg_id]))
  netg <- netg[, list(ratio = sum(ratio)), by = c("seg_id", "id")]

  # emissions of each segment piece (and time bin)
  netg <- emi_seg[netg, on = "seg_id", allow.cartesian = TRUE]

  # adjust emissions by ratio
  for (i in name_emi_new) netg[, (i) := get(i) * ratio]
  
  # 8) Aggregate by TIME-------------------
  
  if(time_resolution != "day"){
    
    # time_resolution
    netg <- netg[
      , lapply(.SD, sum, na.rm = TRUE)
      ,.SDcols = name_emi_new
      ,by = .(timestamp, id)]
    data.table::setorderv(netg, c("id", "timestamp"))
    
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
  for(k in which(!is.na(emi_units))){ # k = 1 (unitless columns stay numeric)
    
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
