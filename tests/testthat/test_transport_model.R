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

  # speeds in other units are converted to km/h (2 km/h and 80 km/h)
  res_ms <- suppressWarnings(suppressMessages(
    transport_model(gtfs_data = gtfs, new_speed = 20, ncores = 1
                    , min_speed = units::set_units(2 / 3.6, "m/s")
                    , max_speed = units::set_units(80 / 3.6, "m/s"))
  ))
  expect_equal(res_ms$speed, res$speed)
})

test_that("fill_speed replaces missing and out-of-range speeds", {
  speed <- c(10, NA, 100, 30)
  dist <- c(1, 1, 1, 3)
  # new_speed given
  expect_equal(fill_speed(speed, dist, 2, 80, new_speed = 20), c(10, 20, 20, 30))
  # otherwise the distance-weighted mean of the valid speeds: (10 * 1 + 30 * 3) / 4 = 25
  expect_equal(fill_speed(speed, dist, 2, 80), c(10, 25, 25, 30))
  # nothing valid and no new_speed
  expect_error(fill_speed(c(NA, 1), c(1, 1), 2, 80), class = "gtfs2emis_error")
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
