#' @title 
#' Transport model 
#' 
#' @description
#'  This function converts a public transport data set in GTFS format into a 
#'  GPS-like table with the space-time positions and speeds of public transport 
#'  vehicles. The function also allow users to set the spatial resolution of the
#'  output and to adjust the speed of public transport vehicles given a 
#'  `min_speed` and `max_speed` range.
#' 
#' @param gtfs_data A path to a GTFS file or a GTFS data organized as a list of 
#'        `data.tables` created with `gtfstools::read_gtfs()`.
#' @param min_speed numeric (in km/h) or a speed units value. Minimum speed to 
#'        be considered as valid. Values below minimum speed will be updated 
#'        according to the `new_speed` parameter, which can affect the arrival 
#'        and  departure times of vehicles at  transit stops. Defaults to `2` 
#'        km/h.
#' @param max_speed numeric (in km/h) or a speed units value. Maximum speed to 
#'        be considered as valid. Values above maximum speed will be  updated 
#'        according to the `new_speed` parameter, which can affect the arrival 
#'        and departure times of vehicles at transit stops. Defaults to `80` 
#'        km/h.
#' @param new_speed numeric (in km/h) or a speed units value. Speed value used 
#'        to replace the speeds that fall outside the `min_speed` and `max_speed` 
#'        range or which are missing from the GTFS input. When `new_speed = NULL` 
#'        (the default), the function uses the average speed of the entire GTFS 
#'        data feed.
#' @param parallel logical. Decides whether the function should run in parallel. 
#'         Defaults is `TRUE`. 
#' @param ncores integer. Number of cores to be used in parallel execution. This 
#'        argument is ignored if parallel is `FALSE`. Default (`NULL`) selects 
#'        the total number of available cores minus one. 
#' @param spatial_resolution The spatial resolution in meters. Defaults to `100`.
#'        The function only creates points in order to guarantee that the 
#'        minimum distance between two consecutive points will be at most the 
#'        `spatial_resolution` value. If a given GTFS shape_id has two 
#'        consecutive points with a distance smaller than the spatial resolution, 
#'        the algorithm will not remove such points. 
#' @param output_path character. A directory path. If `NULL` (Default), the 
#'        function returns the output. If the user passes a valid `passed`, the 
#'        output will be saved in the `output_path` dir. Note that that the 
#'        output of each public transport `shape_id` is saved separately in 
#'        different files. Setting an `output_path` is recommended when working
#'        with large public transport system because the output of the function 
#'        can be significantly large.
#' @param continue logical. Argument that can be used only with output_path When TRUE,
#'        it skips processing the shape identifiers that were already saved into 
#'        files. It is useful to continue processing a GTFS file that was stopped
#'        for some reason. Default value is FALSE.    
#' @return A `data.table sf_linestring` object or `NULL`.
#' 
#' @family Core function
#' 
#' @examples
#' \donttest{
#' if (requireNamespace("gtfstools", quietly=TRUE)) {
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
#'                             min_speed = 2,
#'                             max_speed = 80,
#'                             new_speed = 20,
#'                             spatial_resolution = 100,
#'                             parallel = FALSE)
#'   }
#'}
#' @export
transport_model <- function(gtfs_data
                            , min_speed = 2
                            , max_speed = 80
                            , new_speed = NULL
                            , parallel = TRUE
                            , ncores = NULL
                            , spatial_resolution = 100
                            , output_path = NULL
                            , continue = FALSE){
  
  # check if required fields and files exist  ----
  
  assert_character(output_path,len = 1,null.ok = TRUE)
  if(is.character(output_path)) assert_directory_exists(output_path)
  assert_numeric(min_speed, lower = 2, finite = TRUE, null.ok = TRUE, any.missing = FALSE)  
  assert_numeric(max_speed, lower = 3, finite = TRUE, null.ok = TRUE, any.missing = FALSE)  
  assert_numeric(new_speed, lower = 1, finite = TRUE, null.ok = TRUE, any.missing = FALSE)
  assert_true(min_speed < max_speed, .var.name = "min_speed < max_speed")
  assert_logical(parallel, any.missing = FALSE) 
  
  if(parallel)  assert_integerish(ncores,lower = 1,upper = ncores <- parallelly::availableCores(omit = 1)
                                             ,null.ok = TRUE)
  
  assert_logical(continue, null.ok = FALSE, any.missing = FALSE) 
  # Read GTFS ------------
  
  if (is.character(gtfs_data)) {
    city_gtfs <- gtfstools::read_gtfs(path = gtfs_data)
  }else{
    city_gtfs <- data.table::copy(gtfs_data)
  }
  
  
  # parallel condition
  
  if(parallel){
    # number of cores
    if(is.null(ncores)){
      ncores <- parallelly::availableCores(omit = 1)
      
      cli::cli_inform('Using {ncores} CPU cores')
    }
    
    oplan <- future::plan("multisession", workers = ncores)
    on.exit(future::plan(oplan), add = TRUE)
    
  }
  
  # gtfs2gps ------------
  
  
  gps_path <-  paste0(tempdir(),"//gps//")
  suppressWarnings(dir.create(tempdir()))
  suppressWarnings(dir.create(gps_path))
  
  gtfs2gps::gtfs2gps(gtfs_data = city_gtfs
                     , spatial_resolution = spatial_resolution
                     , parallel = parallel
                     , ncores = ncores
                     , filepath =  gps_path
                     , compress =  TRUE
                     , continue = continue)
  
  
  
  #  Adjusting the speeds of a gps-like table ---------
  
  
  # create new dirs
  gps_adjust_path <-  paste0(tempdir(), "//gps_adjust//")
  suppressWarnings(dir.create(tempdir())) 
  suppressWarnings(dir.create(gps_adjust_path)) 
  
  
  # find gps files
  files_gps <- list.files(gps_path, full.names = TRUE)
  files_gps_names <- list.files(gps_path,full.names = FALSE)
  
  gps_speed_fix <- function(i){ # i =1 
    
    outputfile_path <- paste0(gps_adjust_path
                              ,"//",files_gps_names[i])
    if(continue){
      if(file.exists(outputfile_path)) return(NULL)
    }
    
    tmp_gps <- readRDS(files_gps[i])
    tmp_gps_fix <- gtfs2gps::adjust_speed(gps_data = tmp_gps
                                          ,min_speed = min_speed
                                          ,max_speed = max_speed
                                          ,new_speed = new_speed)
    saveRDS(object = tmp_gps_fix
            ,file = outputfile_path)
    return(NULL)
  }
  if(parallel){
    requiredPackages = c('data.table', 'sf', 'units')
    furrr::future_map(.x = seq_along(files_gps)
                      ,.f = gps_speed_fix
                      ,.options = furrr::furrr_options(
                        seed = TRUE,
                        packages = requiredPackages)) 
    #lapply(seq_along(files_gps),gps_speed_fix)
  }else{
    lapply(seq_along(files_gps),gps_speed_fix)
  }
  
  # GPS as Sf_Linestring ------
  # Converting a GPS-like data.table to a LineString Simple Feature (sf)
  
  # create new dirs
  gps_line_path <-  paste0(output_path,"//")
  if(!is.null(output_path)){
    suppressWarnings(dir.create(gps_line_path))
  }
  
  files_gps <- list.files(gps_adjust_path,full.names = TRUE)
  files_gps_names <- list.files(gps_adjust_path,full.names = FALSE)
  
  # function gps_as_sflinestring
  f_gps_as_sflinestring <- function(i){ # i = 1
    
    outputfile_path <- paste0(gps_line_path,files_gps_names[i])
    if(continue){
      if(file.exists(outputfile_path)) return(NULL)
    }
    
    tmp_gps <- readRDS(files_gps[i])
    tmp_gps_fix <- gtfs2gps::gps_as_sflinestring(gps = tmp_gps)
    tmp_gps_fix$dist <- units::set_units(tmp_gps_fix$dist,"km")
    
    
    if(is.null(output_path)){
      return(tmp_gps_fix)
    }else{
      saveRDS(object =  tmp_gps_fix, 
              file = outputfile_path)
      return(NULL)
    }
    
  }
  
  # Return conditions ----
  if(parallel){
    requiredPackages = c('data.table', 'sf', 'units')
    gpsLine <- furrr::future_map(seq_along(files_gps)
                                 ,f_gps_as_sflinestring
                                 ,.options = furrr::furrr_options(
                                   seed = TRUE,
                                   packages = requiredPackages
                                 )) 
  }else{
    gpsLine <- lapply(seq_along(files_gps),f_gps_as_sflinestring) 
  }
  
  ## This cleans up everything...
  on.exit(unlink(list.files(gps_path,full.names = TRUE)), add = TRUE)
  on.exit(unlink(list.files(gps_adjust_path,full.names = TRUE)), add = TRUE)
  
  
  # output
  if(is.null(output_path)){
    gpsLine <- data.table::rbindlist(gpsLine) 
    suppressWarnings( gpsLine <- sf::st_sf(gpsLine, crs = 4326))
    class(gpsLine) <- c("sf", "data.frame")
    return(gpsLine)
  }else{
    return(NULL)
  }
  
}