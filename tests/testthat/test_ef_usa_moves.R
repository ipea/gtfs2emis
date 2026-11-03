
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
