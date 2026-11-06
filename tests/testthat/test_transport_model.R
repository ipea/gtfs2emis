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
  # otherwise the average speed (total distance / total time) of the capped
  # speeds: (1 + 1 + 3) / (1/10 + 1/80 + 3/30) = 5 / 0.2125 = 23.529...
  expect_equal(fill_speed(speed, dist, 2, 80), c(10, 5 / 0.2125, 80, 30))
  # low speeds are capped at min_speed, Inf at max_speed
  expect_equal(fill_speed(c(1, Inf, 30), c(1, 1, 1), 2, 80), c(2, 80, 30))
  # rows with a missing dist are left out of the mean: (10 * 1) / 1 = 10
  expect_equal(fill_speed(c(10, NA, 30), c(1, 1, NA), 2, 80), c(10, 10, 30))
  # nothing to compute the mean from and no new_speed
  expect_error(fill_speed(c(NA, NA), c(1, 1), 2, 80), class = "gtfs2emis_error")
  expect_error(fill_speed(c(NA, 10), c(1, NA), 2, 80), class = "gtfs2emis_error")

  # the average is taken within each shape:
  # shape a: (100 + 300) / (100/10 + 300/30) = 400 / 20 = 20
  # shape b has no speed, so it gets the feed average:
  # (100 + 300 + 100) / (100/10 + 300/30 + 100/50) = 500 / 22 = 22.727...
  res <- fill_speed(c(10, 30, NA, 50, NA), c(100, 300, 100, 100, 100), 2, 80
                    , group = c("a", "a", "a", "c", "b"))
  expect_equal(res, c(10, 30, 20, 50, 500 / 22))
})

test_that("retime_segments shifts the later times of a trip", {
  t <- function(x) data.table::as.ITime(x)
  # trip A: 3 segments; segment 2 crosses midnight and is capped; 10 s dwell
  #         before segment 3
  # trip B: a capped 0 m segment, then a segment without times
  # trip C: a capped segment that the shift pushes past midnight
  x <- data.frame(
    shape_id = "s",
    trip_id = c("A", "A", "A", "B", "B", "C"),
    trip_number = 1L,
    from_timestamp = t(c("23:58:00", "23:59:10", "00:00:10", "10:00:00", NA, "23:59:00")),
    to_timestamp = t(c("23:59:10", "00:00:00", "00:00:50", "10:00:00", NA, "23:59:50")),
    timestamp = t(c("23:58:00", "23:59:10", "00:00:10", "10:00:00", NA, "23:59:00"))
  )
  x$cumtime <- units::set_units(c(70, 120, 170, 0, NA, 50), "s")
  dist <- c(700, 500, 400, 0, 100, 500)
  speed_old <- 3.6 * dist / c(70, 50, 40, 1, NA, 50)  # km/h
  speed_new <- speed_old
  speed_new[2] <- 10   # capped: 500 m at 10 km/h = 180 s instead of 50 s
  speed_new[4] <- 2    # capped, but 0 m: no change in time
  speed_new[5] <- 20   # filled, but no times: nothing to shift
  speed_new[6] <- 10   # capped: 180 s instead of 50 s

  res <- retime_segments(x, dist, speed_old, speed_new)
  sec <- function(v) as.integer(v)
  # trip A: first departure kept; segment 2 (23:59:10 to 00:00:00, 50 s across
  # midnight) now ends 130 s later, at 00:02:10; segment 3 moves by 130 s
  expect_equal(sec(res$from_timestamp[1:3]), sec(t(c("23:58:00", "23:59:10", "00:02:20"))))
  expect_equal(sec(res$to_timestamp[1:3]), sec(t(c("23:59:10", "00:02:10", "00:03:00"))))
  # the 10 s dwell between segments 2 and 3 is kept
  expect_equal(sec(res$from_timestamp[3]) - sec(res$to_timestamp[2]), 10)
  expect_equal(as.numeric(res$cumtime[1:3]), c(70, 250, 300))
  # trip C: 23:59:50 + 130 s wraps to 00:02:00
  expect_equal(sec(res$to_timestamp[6]), sec(t("00:02:00")))
  expect_s3_class(res$from_timestamp, "ITime")
  expect_equal(res$timestamp, res$from_timestamp)
  # trip B is unchanged
  for (col in c("from_timestamp", "to_timestamp", "timestamp")) {
    expect_equal(as.integer(res[[col]][4:5]), as.integer(x[[col]][4:5]))
  }
  expect_equal(as.numeric(res$cumtime[4:5]), as.numeric(x$cumtime[4:5]))
})

test_that("transport_model gives a time to segments it caps", {
  gtfs <- gtfstools::read_gtfs(system.file("extdata/bra_cur_gtfs.zip", package = "gtfs2emis"))
  # a 2-stop trip whose stops gtfstools places at the same point along the
  # shape (0 m, so set_max_speed() can't fix it) and gtfs2gps 16.8 m apart
  gtfs <- gtfstools::filter_by_trip_id(gtfs, trip_id = "4444371")
  gtfs$stop_times[, `:=`(arrival_time = "09:03:53", departure_time = "09:03:53")]
  res <- suppressMessages(transport_model(gtfs_data = gtfs, ncores = 1))

  duration <- as.integer(res$to_timestamp) - as.integer(res$from_timestamp)
  expect_equal(as.numeric(res$speed), 80)  # Inf, capped
  expect_gt(duration, 0)
  # within 1 s of dist / speed (16.8 m at 80 km/h = 0.76 s, rounded to 1 s)
  expect_lt(abs(duration - 3.6 * as.numeric(units::set_units(res$dist, "m")) / 80), 1)
  expect_equal(as.integer(res$from_timestamp), as.integer(data.table::as.ITime("09:03:53")))
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
  expect_error(transport_model(gtfs_data = gtfs, new_speed = 100, max_speed = 80)
               , class = "gtfs2emis_error")
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
