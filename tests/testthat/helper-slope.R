# Synthetic digital elevation model for the slope tests: height rises linearly
# from west to east with the given grade (m per m), written to tempdir().
make_test_dem <- function(bbox, grade = 0.08, crs = "EPSG:4326", res = 0.0001){
  r <- terra::rast(xmin = bbox[["xmin"]], xmax = bbox[["xmax"]]
                   , ymin = bbox[["ymin"]], ymax = bbox[["ymax"]]
                   , resolution = res, crs = crs)
  x <- terra::xFromCol(r, seq_len(terra::ncol(r)))
  if(terra::is.lonlat(r)){
    # metres per degree of longitude at the centre latitude
    lat <- mean(c(bbox[["ymin"]], bbox[["ymax"]]))
    x <- (x - bbox[["xmin"]]) * 111320 * cos(lat * pi / 180)
  } else {
    x <- x - bbox[["xmin"]]
  }
  terra::values(r) <- rep(1000 + grade * x, times = terra::nrow(r))
  f <- tempfile(fileext = ".tif")
  terra::writeRaster(r, f)
  return(f)
}
