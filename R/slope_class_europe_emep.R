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
#' @param tp_model LineString Simple Feature; transport model output. Geometries must be
#' LINESTRING and have a coordinate reference system; `dist` is in km.
#' @param heightfile character or raster data; The raster file with height data, or its filepath.
#' Its coordinate reference system may differ from the one of `tp_model`.
#' @param keep A logical. Whether the columns related height and slope to the consecutive bus stops 
#' should be kept or dropped (defaults to FALSE, which keeps only the slope classification).
#' @return The transport model (`sf`) with all its columns and a `slope_class` column.
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
#' | slope > +0.070                   |        +0.06     |
#'
#' Heights are read at the first and last vertex of each segment, after projecting
#' them to the coordinate reference system of `heightfile`. Segments with no height
#' (outside the raster) are treated as flat (slope 0), with a warning.
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
  
  # transport model: first and last vertex of each segment
  
  tp_model <- sf::st_as_sf(as.data.frame(tp_model))
  if(any(as.character(sf::st_geometry_type(tp_model)) != "LINESTRING")){
    cli::cli_abort("{.arg tp_model} must have LINESTRING geometries."
                   , class = "gtfs2emis_error")
  }
  if(is.na(sf::st_crs(tp_model))){
    cli::cli_abort("{.arg tp_model} must have a coordinate reference system."
                   , class = "gtfs2emis_error")
  }
  xy <- sf::st_coordinates(tp_model)
  first <- xy[!duplicated(xy[, "L1"]), , drop = FALSE]
  last <- xy[!duplicated(xy[, "L1"], fromLast = TRUE), , drop = FALSE]
  
  # extract height, in the coordinate reference system of the raster
  myraster <- terra::rast(heightfile)
  pts <- sf::st_as_sf(as.data.frame(rbind(first, last)[, c("X", "Y"), drop = FALSE])
                      , coords = c("X", "Y"), crs = sf::st_crs(tp_model))
  if(nzchar(terra::crs(myraster))){
    pts <- sf::st_transform(pts, sf::st_crs(terra::crs(myraster)))
  }
  height <- terra::extract(x = myraster, y = sf::st_coordinates(pts))[[1]]
  
  # heights by segment (empty geometries keep NA)
  n_pts <- nrow(first)
  from_height <- to_height <- rep(NA_real_, nrow(tp_model))
  from_height[first[, "L1"]] <- height[seq_len(n_pts)]
  to_height[last[, "L1"]] <- height[n_pts + seq_len(n_pts)]
  
  # estimate slope
  dh <- to_height - from_height
  slope <- dh / (1000 * as.numeric(tp_model$dist))
  n_na <- sum(is.na(dh))
  if(n_na > 0){
    cli::cli_warn(c(paste0("{n_na} segment{?s} {?has/have} no height in {.arg heightfile} "
                           , "(outside the raster or empty geometry).")
                    , "i" = "Their slope is set to 0 (flat)."))
  }
  slope[!is.finite(slope)] <- 0
  
  slope_class <- data.table::fcase(
    slope <= -0.070, -0.06,
    slope > -0.070 & slope <= -0.050, -0.06,
    slope > -0.050 & slope <= -0.030, -0.04,
    slope > -0.030 & slope <= -0.010, -0.02,
    slope > -0.010 & slope <= +0.010, +0.00,
    slope > +0.010 & slope <= +0.030, +0.02,
    slope > +0.030 & slope <= +0.050, +0.04,
    slope > +0.050 & slope <= +0.070, +0.06,
    slope > +0.070, +0.06
  )
  
  # add columns, keeping the input columns and row order
  tp_model$from_height <- from_height
  tp_model$to_height <- to_height
  tp_model$dh <- dh
  tp_model$slope <- slope
  tp_model$slope_class <- slope_class
  
  if(keep == FALSE){
    tp_model <- tp_model[, setdiff(names(tp_model), c("from_height", "to_height", "dh", "slope"))]
  }
  
  return(tp_model)
}
