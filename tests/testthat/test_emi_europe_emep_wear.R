test_that("emi_europe_emep_wear", {
  
  emi_dt <- emi_europe_emep_wear(dist = units::set_units(c(1,1),"km"),
                               speed =  units::set_units(c(30,30),"km/h"),
                               pollutant = c("PM10","TSP","PM2.5"),
                               veh_type = c("Ubus Std 15 - 18 t","Ubus Artic >18 t"),
                               fleet_composition = c(0.5,0.5),
                               load = 0.5,
                               process = c("brake","tyre","road"),
                               as_list = FALSE)
  
  emi_list <- emi_europe_emep_wear(dist = units::set_units(c(1,1),"km"),
                                 speed =  units::set_units(c(30,30),"km/h"),
                                 pollutant = c("PM10","TSP","PM2.5"),
                                 veh_type = c("Ubus Std 15 - 18 t","Ubus Artic >18 t"),
                                 fleet_composition = c(0.5,0.5),
                                 load = 0.5,
                                 process = c("brake","tyre","road"),
                                 as_list = TRUE)
  
  expect_equivalent(dim(emi_dt), c(2,18))
  
  expect_equivalent(length(emi_list), 7)
  expect_equivalent(length(emi_list$pollutant), 3)
  expect_equivalent(length(emi_list$veh_type), 2)
  expect_equivalent(length(emi_list$process), 3)
})
test_that("emi_europe_emep_wear tyre axles follow veh_type order (#112)", {
  
  tyre_tsp <- function(veh_type, fleet_composition){
    emi <- emi_europe_emep_wear(dist = units::set_units(1, "km"),
                                speed = units::set_units(30, "km/h"),
                                pollutant = "TSP",
                                veh_type = veh_type,
                                fleet_composition = fleet_composition,
                                load = 0.5,
                                process = "tyre")
    return(as.numeric(unlist(emi$emi)))
  }
  
  # EMEP/EEA 1.A.3.b.vi tyre wear: EF = (n_axle / 2) * LCF_t * EF_TSP_PC * S_t(V),
  # with LCF_t = 1.41 + 1.38 * 0.5 = 2.1, EF_TSP_PC = 0.0107 g/km and
  # S_t(30 km/h) = 1.39; an articulated bus has 3 axles
  artic <- 3 / 2 * 2.1 * 0.0107 * 1.39
  expect_equal(tyre_tsp("Ubus Artic >18 t", 1), artic)
  
  # the same fleet listed in a different order gives the same emissions
  std_artic <- tyre_tsp(c("Ubus Std 15 - 18 t", "Ubus Artic >18 t"), c(0.1, 0.9))
  artic_std <- tyre_tsp(c("Ubus Artic >18 t", "Ubus Std 15 - 18 t"), c(0.9, 0.1))
  expect_equal(artic_std, rev(std_artic))
  expect_equal(artic_std[1], 0.9 * artic)
})
test_that("emi_europe_emep_wear brake wear follows EMEP/EEA HDV factor (#113)", {
  
  emi <- emi_europe_emep_wear(dist = units::set_units(c(1, 2), "km"),
                              speed = units::set_units(c(30, 60), "km/h"),
                              pollutant = c("TSP", "PM10"),
                              veh_type = "Ubus Std 15 - 18 t",
                              fleet_composition = 1,
                              load = 0.5,
                              process = "brake")
  
  # EMEP/EEA 1.A.3.b.vi brake wear: EF_HDV = 3.13 * LCF_b * EF_TSP_PC, with
  # LCF_b = 1 + 0.79 * 0.5 = 1.395 and EF_TSP_PC = 0.0075 g/km (~0.0327 g/km);
  # S_b(30 km/h) = 1.67 and S_b(60 km/h) = -0.0270 * 60 + 2.75 = 1.13
  ef_hdv <- 3.13 * 1.395 * 0.0075
  tsp <- c(1, 2) * ef_hdv * c(1.67, 1.13)
  expect_equal(as.numeric(emi$emi$TSP_brake_veh_1), tsp)
  expect_equal(as.numeric(emi$emi$PM10_brake_veh_1), 0.98 * tsp)
})
