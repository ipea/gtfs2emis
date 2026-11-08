test_that("emis_to_dt", {
  
  # Emission Factor
  EF_europe <- ef_europe_emep(pollutant = c("CO", "PM10"),
                              speed = tp_model_irl$speed,
                              veh_type = fleet_data_europe$veh_type,
                              tech = "SCR",
                              euro = fleet_data_europe$euro)
  emi_europe <- multiply_ef(fleet_composition = fleet_data_europe$fleet_composition,
                     dist = tp_model_irl$dist,
                     ef = EF_europe
                     ,aggregate = FALSE)
  emi_europe$tp_model <- tp_model_irl


  emi_europe_before <- data.table::copy(emi_europe)
  # Expect equal -----
  names(emi_europe)
  emi_dt_europe0 <- emis_to_dt(emi_list = emi_europe
                              , veh_vars = c("veh_type","euro","fuel","tech")
                              , segment_vars = c("slope","load")) 
  
  emi_dt_europe1 <- emis_to_dt(emi_list = emi_europe
                              , veh_vars = "fuel") 
  
  emi_dt_europe2 <- emis_to_dt(emi_list = emi_europe
                              , veh_vars = c("veh_type","euro","fuel","tech")) 
  
  emi_dt_europe3 <- emis_to_dt(emi_list = emi_europe) 
  
  # Expect equal-----
  expect_equal(ncol(emi_dt_europe0),9)
  expect_equal(ncol(emi_dt_europe1),4)
  expect_equal(ncol(emi_dt_europe2),7)
  expect_equal(ncol(emi_dt_europe3),4)
  expect_identical(emi_europe, emi_europe_before)
  expect_identical(units::deparse_unit(emi_dt_europe0$emi), "g")
  expect_equal(sum(as.numeric(emi_dt_europe0$emi)), sum(sapply(emi_europe$emi, function(x) sum(as.numeric(x)))))
  #expect_equal(as.numeric(sum(emi_dt_europe0$emi,na.rm = TRUE)),571.9754,0.1) 
  #expect_equal(as.numeric(sum(emi_dt_europe1$emi,na.rm = TRUE)),571.9754,0.1) 
  #expect_equal(as.numeric(sum(emi_dt_europe2$emi,na.rm = TRUE)),571.9754,0.1) 
  #expect_equal(as.numeric(sum(emi_dt_europe3$emi,na.rm = TRUE)),571.9754,0.1) 
  
})
