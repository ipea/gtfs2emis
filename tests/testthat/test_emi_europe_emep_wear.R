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
  
  # EMEP/EEA guidebook 2019, 1.A.3.b.vi brake wear: EF_HDV = 1.956 * LCF_b * EF_TSP_PC
  # (eq. 6), with LCF_b = 1 + 0.79 * 0.5 = 1.395 (eq. 7) and EF_TSP_PC = 0.0122 g/km
  # (Table 3-6), so ~0.0333 g/km; S_b(30 km/h) = 1.67 and
  # S_b(60 km/h) = -0.0270 * 60 + 2.75 = 1.13 (eq. 8); PM10 = 0.98 TSP (Table 3-7)
  ef_hdv <- 1.956 * 1.395 * 0.0122
  tsp <- c(1, 2) * ef_hdv * c(1.67, 1.13)
  expect_equal(as.numeric(emi$emi$TSP_brake_veh_1), tsp)
  expect_equal(as.numeric(emi$emi$PM10_brake_veh_1), 0.98 * tsp)
})

test_that("emi_europe_emep_wear: lengths of speed, dist and load are checked", {
  dist <- units::set_units(c(1, 2), "km")
  veh <- "Ubus Std 15 - 18 t"
  expect_error(emi_europe_emep_wear(dist, units::set_units(c(30, 50, 60), "km/h"), "PM10", veh, 1)
               , class = "gtfs2emis_error")
  expect_error(emi_europe_emep_wear(dist, units::set_units(c(30, 50), "km/h"), "PM10", veh, 1
                                    , load = c(0.2, 0.5, 0.8))
               , class = "gtfs2emis_error")
  # a single speed is used for every segment
  one <- emi_europe_emep_wear(dist, units::set_units(30, "km/h"), "PM10", veh, 1)
  two <- emi_europe_emep_wear(dist, units::set_units(c(30, 30), "km/h"), "PM10", veh, 1)
  expect_equal(one$emi, two$emi)
})

test_that("emi_europe_emep_wear: brake wear with one load per segment", {
  dist <- units::set_units(c(1, 2), "km")
  speed <- units::set_units(c(30, 50), "km/h")
  veh <- c("Ubus Std 15 - 18 t", "Ubus Artic >18 t")
  emi <- function(load, i) emi_europe_emep_wear(dist[i], speed[i], "PM10", veh, c(0.4, 0.6)
                                                , load = load, process = "brake")$emi
  both <- emi(c(0.2, 0.8), 1:2)
  expect_equal(dim(both), c(2L, 2L))
  expect_equal(both[1, ], emi(0.2, 1))
  expect_equal(both[2, ], emi(0.8, 2))
})

test_that("emi_europe_emep_wear: PM1.0 tyre and brake wear", {
  # EMEP/EEA 2019, 1.A.3.b.vi, size distributions: PM1.0 is 0.060 of TSP for
  # tyre wear (PM10: 0.600) and 0.100 of TSP for brake wear (PM10: 0.980)
  dist <- units::set_units(c(1, 2), "km")
  speed <- units::set_units(c(30, 50), "km/h")
  veh <- "Ubus Std 15 - 18 t"
  for (p in c("tyre", "brake")) {
    pm1 <- emi_europe_emep_wear(dist, speed, "PM1.0", veh, 1, process = p)$emi[[1]]
    pm10 <- emi_europe_emep_wear(dist, speed, "PM10", veh, 1, process = p)$emi[[1]]
    ratio <- if (p == "tyre") 0.060 / 0.600 else 0.100 / 0.980
    expect_equal(as.numeric(pm1), as.numeric(pm10) * ratio)
  }
})
