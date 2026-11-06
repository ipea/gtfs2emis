
test_that("ef_scaled_euro", {
  result <- ef_scaled_euro(
    ef_local = units::set_units(0.5,g/km),
    speed = units::set_units(30,km/h),
    euro = "V", 
    SDC = units::set_units(19,km/h),
    veh = "Ubus Std 15 - 18 t",
    pollutant = "CO")
  
  expect_equal(names(result)
               ,c("pollutant", "veh_type", "euro", "fuel", "tech", "process","slope", "load", "speed","EF"))
  #expect_equal(as.numeric(result$EF),0.3370477,tolerance = 0.001)

  
#  expect_equal(sum(result), 36.14574, 0.001)
})

test_that("ef_scaled_euro accepts a slope vector; reference at slope 0 (G-32)", {
  ef <- function(speed, slope = 0){
    suppressMessages(
      ef_scaled_euro(ef_local = units::set_units(0.5, "g/km")
                     , speed = units::set_units(speed, "km/h")
                     , veh_type = "Ubus Std 15 - 18 t"
                     , euro = "V"
                     , pollutant = "CO"
                     , slope = slope)
    )$EF[[1]]
  }
  # a slope vector used to crash
  res <- ef(c(20, 30, 20, 30), slope = c(0, 0.02, 0, 0.02))
  expect_length(res, 4)
  expect_equal(as.numeric(res[c(1, 3)]), as.numeric(ef(c(20, 20))))
  # the gradient is not cancelled by the reference
  expect_false(isTRUE(all.equal(as.numeric(res[c(2, 4)]), as.numeric(ef(c(30, 30))))))
  # at the reference speed on a flat road the local factor is returned
  expect_equal(as.numeric(ef(19)), 0.5)
})
