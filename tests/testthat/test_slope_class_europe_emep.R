
test_that("slope_class_europe_emep", {
  gtfs_file <- system.file("extdata/bra_cur_gtfs.zip", package = "gtfs2emis")
  gtfs <- gtfstools::read_gtfs(gtfs_file) 
  # keep a single trip_id to speed up this example
  gtfs_small <- gtfstools::filter_by_trip_id(gtfs, trip_id ="4451136")
    
  # run transport model
  tp_model <- transport_model(gtfs_data = gtfs_small,
                              min_speed = 2,
                              max_speed = 80,
                              new_speed = 20,
                              spatial_resolution = 100)
  
  # read raster file
  raster_cur <- system.file("extdata/bra_cur-srtm.tif", package = "gtfs2emis")
  
  tp_model_slope <- slope_class_europe_emep(tp_model,raster_cur)
  
  expect_equal(tp_model_slope$slope_class, rep(0.0, nrow(tp_model)), 0.001)
  expect_equivalent(nrow(tp_model_slope), nrow(tp_model))
  expect_equivalent(ncol(tp_model_slope), ncol(tp_model) + 1) # input columns + slope_class
  
  tp_model_slope_true <- slope_class_europe_emep(tp_model,raster_cur,keep = TRUE)
  expect_equivalent(nrow(tp_model_slope_true), nrow(tp_model))
  expect_equivalent(ncol(tp_model_slope_true), ncol(tp_model) + 5)
  })

test_that("slope_class_europe_emep uses each segment's endpoints (G-44/45/46)", {

  # two trips on two shapes with repeated stop_sequence; 8% grade west -> east
  seg <- function(x1, y1, x2, y2) sf::st_linestring(rbind(c(x1, y1), c(x2, y2)))
  geom <- sf::st_sfc(seg(-49.290, -25.43, -49.285, -25.43)   # east: uphill
                     , seg(-49.280, -25.43, -49.285, -25.43) # west: downhill
                     , seg(-49.270, -25.43, -49.270, -25.425)# north: flat
                     , seg(-49.000, -25.43, -48.995, -25.43) # outside the raster
                     , sf::st_linestring(matrix(numeric(0), ncol = 2)) # empty
                     , crs = 4326)
  tp <- sf::st_sf(shape_id = c("a", "a", "b", "b", "b")
                  , trip_id = c("1", "1", "2", "2", "2")
                  , stop_sequence = c(1L, 2L, 1L, 2L, 3L)
                  , my_col = letters[1:5]
                  , dist = units::set_units(as.numeric(sf::st_length(geom)) / 1000, "km")
                  , geometry = geom)
  tp_input <- tp
  dem <- make_test_dem(c(xmin = -49.30, xmax = -49.25, ymin = -25.45, ymax = -25.40))

  expect_warning(res <- slope_class_europe_emep(tp, dem, keep = TRUE), "no height")

  # slope > 7% is +0.06 (G-44); segments do not mix across trips (G-45)
  expect_equal(res$slope_class, c(0.06, -0.06, 0, 0, 0))
  expect_equal(res$slope[1:2], c(0.08, -0.08), tolerance = 0.01)
  # input columns and row order are kept (G-46); the input is not changed
  expect_equal(res$my_col, tp$my_col)
  expect_equal(res$stop_sequence, tp$stop_sequence)
  expect_identical(tp, tp_input)

  # a raster in another CRS (UTM 22S) gives the same classes
  tp_utm <- sf::st_transform(tp[1:3, ], 32722)
  dem_utm <- make_test_dem(sf::st_bbox(sf::st_buffer(tp_utm, 500)), crs = "EPSG:32722", res = 10)
  res_utm <- slope_class_europe_emep(tp[1:3, ], dem_utm)
  expect_equal(res_utm$slope_class, c(0.06, -0.06, 0))
})
