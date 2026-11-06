gtfs_cur_trip <- function(){
  gtfs <- gtfstools::read_gtfs(system.file("extdata/bra_cur_gtfs.zip", package = "gtfs2emis"))
  gtfstools::filter_by_trip_id(gtfs, trip_id = "4451136")
}

test_that("transport_model returns in-trip segments with valid speeds", {
  gtfs <- gtfs_cur_trip()
  res <- suppressWarnings(suppressMessages(
    transport_model(gtfs_data = gtfs, new_speed = 20, ncores = 1)
  ))

  expect_identical(class(res), c("sf", "data.frame"))
  expect_s3_class(res$speed, "units")
  expect_equal(units::deparse_unit(res$dist), "km")
  # no shape tails outside the trip, no missing speeds or timestamps
  expect_false(anyNA(res$speed))
  expect_false(anyNA(res$timestamp))
  expect_false(anyNA(res$from_timestamp))
  expect_false(anyNA(res$to_timestamp))
  # speeds are within min_speed and max_speed (defaults 2 and 80 km/h)
  expect_true(all(as.numeric(res$speed) >= 2 & as.numeric(res$speed) <= 80))
  # the Dublin fixture (setup.R) has segments that need capping
  expect_false(anyNA(tp_model_irl$speed))
  expect_true(all(as.numeric(tp_model_irl$speed) >= 2 & as.numeric(tp_model_irl$speed) <= 80))

  # speeds in other units are converted to km/h (2 km/h and 80 km/h)
  res_ms <- suppressWarnings(suppressMessages(
    transport_model(gtfs_data = gtfs, new_speed = 20, ncores = 1
                    , min_speed = units::set_units(2 / 3.6, "m/s")
                    , max_speed = units::set_units(80 / 3.6, "m/s"))
  ))
  expect_equal(res_ms$speed, res$speed)
})

test_that("fill_speed caps out-of-range speeds and fills missing ones", {
  speed <- c(10, NA, 100, 30)
  dist <- c(1, 1, 1, 3)
  # 100 is capped at max_speed; NA becomes new_speed
  expect_equal(fill_speed(speed, dist, 2, 80, new_speed = 20), c(10, 20, 80, 30))
  # otherwise the distance-weighted mean of the capped speeds:
  # (10 * 1 + 80 * 1 + 30 * 3) / (1 + 1 + 3) = 180 / 5 = 36
  expect_equal(fill_speed(speed, dist, 2, 80), c(10, 36, 80, 30))
  # low speeds are capped at min_speed, Inf at max_speed
  expect_equal(fill_speed(c(1, Inf, 30), c(1, 1, 1), 2, 80), c(2, 80, 30))
  # rows with a missing dist are left out of the mean: (10 * 1) / 1 = 10
  expect_equal(fill_speed(c(10, NA, 30), c(1, 1, NA), 2, 80), c(10, 10, 30))
  # nothing to compute the mean from and no new_speed
  expect_error(fill_speed(c(NA, NA), c(1, 1), 2, 80), class = "gtfs2emis_error")
  expect_error(fill_speed(c(NA, 10), c(1, NA), 2, 80), class = "gtfs2emis_error")
})

test_that("transport_model gives one segment per pair of consecutive stops", {
  gtfs <- gtfstools::read_gtfs(system.file("extdata/usa_det_gtfs.zip", package = "gtfs2emis"))
  # two trips of shape shp-3-05 with 11 and 7 stops; gtfs2gps 2.1-4 gave 6 segments to both
  gtfs <- gtfstools::filter_by_trip_id(gtfs, trip_id = c("197020", "6056020"))
  gtfs_before <- data.table::copy(gtfs)
  res <- suppressMessages(transport_model(gtfs_data = gtfs, new_speed = 20, ncores = 1))

  n_stops <- table(gtfs$stop_times$trip_id)
  n_seg <- table(res$trip_id)
  expect_equal(as.vector(n_seg[names(n_stops)]), as.vector(n_stops) - 1)
  expect_true(all(res$to_timestamp > res$from_timestamp))
  expect_identical(gtfs, gtfs_before)

  # invalid speeds
  expect_error(transport_model(gtfs_data = gtfs, min_speed = 1), class = "gtfs2emis_error")
  expect_error(transport_model(gtfs_data = gtfs, min_speed = 50, max_speed = 40)
               , class = "gtfs2emis_error")

  # nothing to convert
  empty <- gtfstools::filter_by_trip_id(gtfs, trip_id = "nonexistent")
  expect_error(suppressMessages(transport_model(gtfs_data = empty, ncores = 1))
               , class = "gtfs2emis_error")
})

test_that("transport_model saves one .rds per shape with output_path", {
  gtfs <- gtfs_cur_trip()
  out <- file.path(tempdir(), "tp_model_files")
  dir.create(out, showWarnings = FALSE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  res <- suppressWarnings(suppressMessages(
    transport_model(gtfs_data = gtfs, new_speed = 20, ncores = 1, output_path = out)
  ))
  expect_null(res)
  files <- list.files(out, pattern = "\\.rds$")
  expect_equal(files, paste0(unique(gtfs$trips$shape_id), ".rds"))

  # a shape_id with "%" round-trips through its file name
  gtfs_pct <- data.table::copy(gtfs)
  gtfs_pct$trips[, shape_id := "x%20y"]
  gtfs_pct$shapes[, shape_id := "x%20y"]
  out2 <- file.path(tempdir(), "tp_model_files_pct")
  dir.create(out2, showWarnings = FALSE)
  on.exit(unlink(out2, recursive = TRUE), add = TRUE)
  suppressMessages(transport_model(gtfs_data = gtfs_pct, new_speed = 20, ncores = 1
                                   , output_path = out2))
  files2 <- list.files(out2, pattern = "\\.rds$")
  expect_equal(utils::URLdecode(sub("\\.rds$", "", files2)), "x%20y")

  fleet <- data.frame(veh_type = "Ubus Std 15 - 18 t", euro = "V", fuel = "D"
                      , tech = "SCR", fleet_composition = 1)
  emi <- suppressMessages(emission_model(tp_model = out, ef_model = "ef_europe_emep"
                                         , fleet_data = fleet, pollutant = "NOx"
                                         , parallel = FALSE))
  expect_false(anyNA(as.numeric(emi$emi[[1]])))
})

test_that("transport_model: `parallel` and `continue` are deprecated and ignored", {
  gtfs <- gtfs_cur_trip()

  # using them gives a classed warning
  expect_warning(
    res_par <- suppressMessages(transport_model(gtfs_data = gtfs, new_speed = 20, ncores = 1
                                                , parallel = FALSE))
    , class = "gtfs2emis_deprecated"
  )
  expect_warning(
    suppressMessages(transport_model(gtfs_data = gtfs, new_speed = 20, ncores = 1
                                     , continue = FALSE))
    , class = "gtfs2emis_deprecated"
  )

  # not using them gives no deprecation warning, and the same result
  res <- tryCatch(suppressMessages(transport_model(gtfs_data = gtfs, new_speed = 20, ncores = 1))
                  , gtfs2emis_deprecated = function(w) "warned")
  expect_false(identical(res, "warned"))
  expect_equal(res, res_par)
})
