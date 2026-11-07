
test_that("emis_grid", {
  
  
  my_emis <- emission_model(tp_model_irl
                            ,"ef_europe_emep"
                            ,fleet_data_europe
                            ,pollutant = c("CO","PM10","NOx"))
  grid <- sf::st_make_grid(tp_model_irl
                               , cellsize = 0.25 / 102.47
                               , square = FALSE
                               , crs = 4326
  ) 
  
  my_emis_before <- data.table::copy(my_emis)
  pol_gps        <- emis_grid(my_emis, grid)
  pol_gps_hour   <- emis_grid(my_emis, grid,time_resolution = "hour")
  pol_gps_minute <- emis_grid(my_emis, grid,time_resolution = "minute")
  pol_gps_agr     <- emis_grid(my_emis, grid,aggregate = TRUE)
  
  dim(pol_gps        )
  dim(pol_gps_hour   )
  dim(pol_gps_minute )
  dim(pol_gps_agr    )
  # Expect equal -----
  # Values for gtfs2gps >= 2.1-4.9000: one segment per pair of consecutive
  # stops (73). gtfs2gps 2.1-4 gave 90 segments and timed trip 3412
  # (08:00-08:23) at 16:27-17:00, so it had no 08 h and 5 fewer cells.
  expect_equal(dim(pol_gps), c(42,10))
  expect_equal(dim(pol_gps_hour   ), c(188,11))
  expect_equal(dim(pol_gps_minute ), c(306,11))
  expect_equal(dim(pol_gps_agr    ), c(42,4))
  # the time resolution only splits the emissions of each cell; the input is unchanged
  tot <- function(x) sum(as.numeric(x[[names(my_emis$emi)[1]]]), na.rm = TRUE)
  expect_equal(tot(pol_gps_hour), tot(pol_gps))
  expect_equal(tot(pol_gps_minute), tot(pol_gps))
  expect_identical(my_emis, my_emis_before)
  #expect_equal(as.numeric(sum(pol_gps$CO_total)), 544.01,0.01)
  #expect_equal(as.numeric(sum(pol_gps_hour$CO_total)), 544.01,0.01)
  #expect_equal(as.numeric(sum(pol_gps_hour_minute$CO_total)), 544.01,0.01)
  
  
})

test_that("emis_grid: totals, CRS and units on geographic and projected grids", {
  
  my_emis <- emission_model(tp_model_irl, "ef_europe_emep", fleet_data_europe
                            , pollutant = c("CO", "PM10"), quiet = TRUE)
  street_total <- sum(sapply(my_emis$emi, function(x) sum(as.numeric(x))))
  grid_total <- function(x) sum(sapply(names(my_emis$emi)
                                       , function(i) sum(as.numeric(x[[i]]), na.rm = TRUE)))
  s2_before <- sf::sf_use_s2()
  for (crs in c(4326, 3857)) {
    emis_crs <- my_emis
    emis_crs$tp_model <- sf::st_transform(my_emis$tp_model, crs)
    grid <- sf::st_make_grid(emis_crs$tp_model, n = c(8, 8))
    out <- emis_grid(emis_crs, grid)
    # each segment's emissions are split between cells, none lost or added
    expect_equal(grid_total(out), street_total, tolerance = 1e-6)
    expect_equal(sf::st_crs(out), sf::st_crs(grid))
    expect_true(all(sf::st_geometry(out) %in% grid))
    expect_identical(units::deparse_unit(out[[names(my_emis$emi)[1]]]), "g")
  }
  expect_identical(sf::sf_use_s2(), s2_before)
  
  # emission columns without units stay numeric
  no_units <- my_emis
  no_units$emi <- data.table::as.data.table(lapply(my_emis$emi, as.numeric))
  out <- emis_grid(no_units, sf::st_make_grid(my_emis$tp_model, n = c(8, 8)))
  expect_type(out[[names(my_emis$emi)[1]]], "double")
  expect_message(emis_grid(no_units, sf::st_make_grid(my_emis$tp_model, n = c(8, 8)), quiet = FALSE)
                 , "Sum of gridded emissions")
  expect_equal(grid_total(out), street_total, tolerance = 1e-6)
})
