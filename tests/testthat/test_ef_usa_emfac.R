
test_that("ef_usa_emfac", {
  
  EF_usa <- ef_usa_emfac(pollutant = c("CO","PM10"),
                         reference_year = 2019,
                         model_year = fleet_data_usa$model_year,
                         speed = tp_model_irl$speed,
                         fuel = "D")
  
  # Expect equal----
  expect_equal(names(EF_usa),c("pollutant","model_year","veh_type","fuel","EF", "process"))
  #expect_equal(as.numeric(sum(EF_usa$EF,na.rm = TRUE)), 195.2403, 0.01)
  
  # Expect error----
  
  # speed as.numeric
  expect_error(
    object = ef_usa_emfac(pollutant = c("CO","PM10"),
                          model_year = fleet_data_usa$year,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # speed out or range
  expect_error(
    object = ef_usa_emfac(pollutant = c("CO","PM10"),
                          reference_year = 2020,
                          model_year = fleet_data_usa$year,
                          speed = units::set_units(800,"km/h"),
                          fuel = "D")
    )
  expect_error(
    object = ef_usa_emfac(pollutant = c("CO","PM10"),
                          reference_year = 2020,
                          model_year = fleet_data_usa$year,
                          speed = units::set_units(0,"km/h"),
                          fuel = "D")
    )
  # reference_year - as.numeric
  expect_error(
    object = ef_usa_emfac(pollutant = c("CO","PM10"),
                          model_year = fleet_data_usa$year,
                          reference_year = "2015",
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # reference_year out of range
  expect_error(
    object = ef_usa_emfac(pollutant = c("CO","PM10"),
                          model_year = fleet_data_usa$year,
                          reference_year = 2080,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # reference_year duplicated
  expect_error(
    object = ef_usa_emfac(pollutant = c("CO","PM10"),
                          reference_year = c(2019,2019),
                          model_year = fleet_data_usa$year,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # pollutant wrong
  expect_error(
    object = ef_usa_emfac(pollutant = c("banana"),
                          model_year = fleet_data_usa$year,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "D")
  )
  # wrong fuel
  expect_error(
    object = ef_usa_emfac(pollutant = c("CO","PM10"),
                          model_year = fleet_data_usa$year,
                          speed = as.numeric(tp_model_irl$speed),
                          fuel = "banana")
  )

  })

test_that("ef_usa_emfac: a speed on a bin limit uses that bin", {
  
  # ef_usa_emfac_db speed bins are (lower_speed_interval, upper_speed_interval]:
  # 8 km/h is in the first bin, 8.1 in the second
  speed <- units::set_units(c(1, 8, 8.1, 16, 113), "km/h")
  ef <- ef_usa_emfac(pollutant = "CO", reference_year = 2019, fuel = "D",
                     model_year = 2015, speed = speed, as_list = FALSE)
  all_db <- data.table::as.data.table(ef_usa_emfac_db)
  db <- all_db[reference_year == 2019 & model_year == 2015 & fuel == "D" & pollutant == "CO"]
  # the lookup takes the k-th row of each group, so every group must be sorted
  expect_true(all(all_db[, !is.unsorted(upper_speed_interval)
                         , by = .(reference_year, model_year, fuel, pollutant)]$V1))
  expected <- as.numeric(db$ef)[match(c(8, 8, 16, 16, 113), as.numeric(db$upper_speed_interval))]
  expect_equal(as.numeric(ef[[1]]), expected)
})
