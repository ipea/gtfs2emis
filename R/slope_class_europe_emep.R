#' Add slope class into the transport model (LineString Simple Feature object)
#'
#' Based on the input height data, the function returns the slope class between two consecutive 
#' bus stop positions of a LineString Simple Feature (transport model object).
#'  The slope is given by the ratio between the height difference and 
#'  network distance from two consecutive public transport stops.
#'  The function classifies the slope into one of the seven categories
#' available on the European Environmental Agency (EEA) database, which is -0.06,
#'  -0.04,-0.02, 0.00, 0.02, 0.04, and 0.06. The classifications is described in
#'  @details .
#'  
#' @param tp_model LineString Simple Feature; transport model output.
#' @param heightfile character or raster data; The raster file with height data, or its filepath.
#' @param keep A logical. Whether the columns related height and slope to the consecutive bus stops 
#' should be kept or dropped (defaults to FALSE, which keeps only the slope classification).
#' @return The transport model with slope information.
#'
#' @details 
#' # Slopes classification:
#' |  **slope interval**              |  **slope class** |
#' | slope <= -0.070                  |        -0.06     |
#' | slope > -0.070 & slope <= -0.050 |        -0.06     |
#' | slope > -0.050 & slope <= -0.030 |        -0.04     |
#' | slope > -0.030 & slope <= -0.010 |        -0.02     |
#' | slope > -0.010 & slope <= +0.010 |        +0.00     |
#' | slope > +0.010 & slope <= +0.030 |        +0.02     |
#' | slope > +0.030 & slope <= +0.050 |        +0.04     |
#' | slope > +0.050 & slope <= +0.070 |        +0.06     |
#' | slope > +0.070                   |        -0.06     |
#' @examples
#' \donttest{
#'  if (requireNamespace("gtfstools", quietly=TRUE)) {
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
#' 
#' # read raster file
#' raster_cur <- system.file("extdata/bra_cur-srtm.tif", package = "gtfs2emis")
#' 
#' tp_model_slope <- slope_class_europe_emep(tp_model,raster_cur)
#' }
#' }
#' @export
slope_class_europe_emep <- function(tp_model,heightfile,keep = FALSE){
  
  # checks
  assert_class(tp_model, classes = c("sf", "data.frame"),null.ok = FALSE)
  assert_checks(
    checkmate::check_class(heightfile, classes = c("RasterLayer","Raster"),null.ok = FALSE)
    , checkmate::check_class(heightfile, classes = c("character"),null.ok = FALSE)
    , combine = "or", .var.name = "heightfile"
  )
  if(is.character(heightfile)) assert_file_exists(heightfile)
  assert_logical(keep, null.ok = FALSE)
  
  # transport model
  
  tmpGps <- sfheaders::sf_cast(tp_model,to = "POINT")
  data.table::setDT(tmpGps)
  tmpGps <- tmpGps[,.SD[c(1,.N)],by = .(stop_sequence)]
  tmpGps <- sf::st_as_sf(tmpGps)
  tmpGps <- sf::st_coordinates(tmpGps)
  
  # extract height
  myraster <- terra::rast(heightfile)
  result <- terra::extract(x = myraster,y = tmpGps)
  tp_model$from_height <- result[[1]][seq(1,nrow(result),2)]
  tp_model$to_height <- result[[1]][seq(2,nrow(result),2)]
  data.table::setDT(tp_model)
  
  # estimate slope
  tp_model <- tp_model[,{
    dh = to_height - from_height
    ds = 1000 * as.numeric(dist)
    
    slope = dh / ds
    slope[is.infinite(slope)] <- 0 
    slope[is.nan(slope)] <- 0 
    
    slope_class <- data.table::fcase(
      #slope <= -0.070,NA_real_,
      slope <= -0.070, -0.06,
      slope > -0.070 & slope <= -0.050, -0.06,
      slope > -0.050 & slope <= -0.030, -0.04,
      slope > -0.030 & slope <= -0.010, -0.02,
      slope > -0.010 & slope <= +0.010, +0.00,
      slope > +0.010 & slope <= +0.030, +0.02,
      slope > +0.030 & slope <= +0.050, +0.04,
      slope > +0.050 & slope <= +0.070, +0.06,
      slope > +0.070,-0.06
      # slope > +0.070,NA_real_
    )  
    
    list(speed, dist,
         cumdist, cumtime, trip_number,
         from_stop_id, to_stop_id, from_timestamp, to_timestamp,
         from_height, to_height, dh,slope, slope_class, geometry)
  },by = .(shape_id, trip_id, route_type,stop_sequence)]
  
  if(keep == FALSE){
    tp_model <- tp_model[,.SD,.SDcols = !c( "from_height", "to_height", "dh","slope")]
  }
  
  return(sf::st_as_sf(tp_model))
}
