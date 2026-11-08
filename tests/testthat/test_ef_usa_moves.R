
test_that("ef_usa_moves", {
  
  EF_usa <- ef_usa_moves(pollutant = c("CO","PM10"),
                         reference_year = 2019,
                         model_year = fleet_data_usa$model_year,
                         speed = tp_model_irl$speed,
                         fuel = "D")
  
  # Expect equal----
  expect_equal(names(EF_usa),c("pollutant" ,"model_year","veh_type","fuel","EF","process"))
  #expect_equal(as.numeric(sum(EF_usa$EF,na.rm = TRUE)), 43671.76, 0.1)
  
  # Expect error----
  
  # speed as.numeric
  expect_error(
    object = ef_usa_moves(pollutant = c("CO","PM10"),
                          model_year = fleet_data_usa$year,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # speed out or range
  expect_error(
    object = ef_usa_moves(pollutant = c("CO","PM10"),
                          reference_year = 2020,
                          model_year = fleet_data_usa$year,
                          speed = units::set_units(800,"km/h"),
                          fuel = "D"))
  expect_error(
    object = ef_usa_moves(pollutant = c("CO","PM10"),
                          reference_year = 2020,
                          model_year = fleet_data_usa$year,
                          speed = units::set_units(0,"km/h"),
                          fuel = "D"))
  # reference_year - as.numeric
  expect_error(
    object = ef_usa_moves(pollutant = c("CO","PM10"),
                          model_year = fleet_data_usa$year,
                          reference_year = "2015",
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # reference_year out of range
  expect_error(
    object = ef_usa_moves(pollutant = c("CO","PM10"),
                          model_year = fleet_data_usa$year,
                          reference_year = 2080,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # reference_year duplicated
  expect_error(
    object = ef_usa_moves(pollutant = c("CO","PM10"),
                          reference_year = c(2019,2019),
                          model_year = fleet_data_usa$year,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # pollutant wrong
  expect_error(
    object = ef_usa_moves(pollutant = c("banana"),
                          model_year = fleet_data_usa$year,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # wrong fuel
  expect_error(
    object = ef_usa_moves(pollutant = c("CO","PM10"),
                          model_year = fleet_data_usa$year,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "banana")
  )
})

test_that("ef_usa_moves pairs each fuel with its own EF (#111)", {
  
  speed <- units::set_units(c(10, 50), "km/h")
  ef_d <- ef_usa_moves(pollutant = "CO", model_year = 2015, reference_year = 2019,
                       speed = speed, fuel = "D")
  ef_cng <- ef_usa_moves(pollutant = "CO", model_year = 2015, reference_year = 2019,
                         speed = speed, fuel = "CNG")
  ef_mix <- ef_usa_moves(pollutant = "CO", model_year = c(2015, 2015), reference_year = 2019,
                         speed = speed, fuel = c("D", "CNG"))
  
  expect_equal(as.numeric(ef_mix$EF[[1]]), as.numeric(ef_d$EF[[1]]))
  expect_equal(as.numeric(ef_mix$EF[[2]]), as.numeric(ef_cng$EF[[1]]))
})

test_that("ef_usa_moves: a speed on a bin limit uses that bin", {
  
  # ef_usa_moves_db speed bins are (lower_speed_interval, upper_speed_interval]:
  # 4 km/h is in the first bin, 4.05 in the second
  speed <- units::set_units(c(1, 4, 4.05, 12.1, 120.7), "km/h")
  ef <- ef_usa_moves(pollutant = "CO", model_year = 2015, reference_year = 2019,
                     speed = speed, fuel = "D", as_list = FALSE)
  all_db <- data.table::as.data.table(ef_usa_moves_db)
  db <- all_db[reference_year == 2019 & model_year == 2015 & fuel_type == "D" & pollutant == "CO"]
  # the lookup takes the k-th row of each group, so every group must be sorted
  expect_true(all(all_db[, !is.unsorted(upper_speed_interval)
                         , by = .(reference_year, model_year, fuel_type, pollutant)]$V1))
  expected <- as.numeric(db$ef)[match(c(4, 4, 12.1, 12.1, 120.7), as.numeric(db$upper_speed_interval))]
  expect_equal(as.numeric(ef[[1]]), expected)
})
