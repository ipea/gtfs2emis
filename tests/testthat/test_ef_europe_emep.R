test_that("ef_europe_emep", {
  # GTFS2gps filter
  
  # gtfs2emis
  EF_europe <- ef_europe_emep(pollutant = c("CO", "PM10"),
                              speed = tp_model_irl$speed,
                              veh_type = fleet_data_europe$veh_type,
                              tech = "SCR",
                              euro = fleet_data_europe$euro)
  
  # Expect equal -----
  expect_equal(length(EF_europe), 10)
  expect_equal(length(EF_europe$pollutant), 2)
  expect_equal(length(EF_europe$veh_type), 3)
  expect_equal(length(EF_europe$euro), 3)
  expect_equal(units::deparse_unit(EF_europe$EF$CO_Euro_II), "g km-1")
 # expect_equal(sum(EF_europe$EF,na.rm = TRUE), 1188.842,0.1)
  
  
  # Expect error-----
  # speed
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(NA,1,2),"km/h")
                   ,veh_type = fleet_data_europe$veh_type
                   ,tech = "SCR"
                   ,euro = fleet_data_europe$euro)
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,200),"km/h")
                   ,veh_type = fleet_data_europe$veh_type
                   ,tech = "SCR"
                   ,euro = fleet_data_europe$euro)
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,200),"km")
                   ,veh_type = fleet_data_europe$veh_type
                   ,tech = "SCR"
                   ,euro = fleet_data_europe$euro)
  )
  # veh_type
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = c("Ubus Midi <=15 t",NA)
                   ,tech = "SCR"
                   ,euro = fleet_data_europe$euro)
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = c("banana")
                   ,tech = "SCR"
                   ,euro = fleet_data_europe$euro)
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = 23213
                   ,tech = "SCR"
                   ,euro = fleet_data_europe$euro)
  )
  # euro
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = c("III",NA))
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = c("banana"))
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = 123)
  )
  # fuel
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = c("III"),fuel = c(NA,"D"))
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = c("III"),fuel = c("banana"))
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", "PM")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = "III",fuel = 1231)
  )
  # pollutant
  expect_error(
    ef_europe_emep(pollutant = c("CO", NA)
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = c("III"))
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", "banana")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = c("III"))
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO", 2132)
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = "III")
  )
  # tech
  expect_error(
    ef_europe_emep(pollutant = c("CO")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = c("SCR",NA)
                   ,euro = c("III"))
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "banana"
                   ,euro = c("III"))
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = 1231
                   ,tech = "SCR"
                   ,euro = "III")
  )
  # as_list
  expect_error(
    ef_europe_emep(pollutant = c("CO")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = "III",as_list = 123)
  )
  # lengths
  expect_error(
    ef_europe_emep(pollutant = c("CO")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = "III",slope = rep(0.02,2))
  )
  expect_error(
    ef_europe_emep(pollutant = c("CO")
                   ,speed = units::set_units(c(1,2,20),"km/h")
                   ,veh_type = "Ubus Midi <=15 t"
                   ,tech = "SCR"
                   ,euro = "III",load = rep(1,2))
  )
})

test_that("EMEP FC is g/km and keys are unique (#110)", {
  # EMEP/EEA guidebook 2019, 1.A.3.b.i-iv: FC [g/km] = EC [MJ/km] / NCV [MJ/kg] * 1000
  # (Table 3-28, diesel NCV = 42.695) and CNG CO2 = FC * 44.011 / (12.011 + 1.008 * 4)
  # (equation 16, Table 3-29)
  ef <- function(pollutant, euro, fuel = "D", tech = "-"){
    suppressMessages(
      ef_europe_emep(speed = units::set_units(30, "km/h")
                     , veh_type = "Ubus Std 15 - 18 t"
                     , euro = euro
                     , pollutant = pollutant
                     , fuel = fuel
                     , tech = tech)
    )$EF[[1]]
  }

  # diesel Conventional: EC 14.44 MJ/km -> about 338 g/km
  ec <- as.numeric(ef("EC", "Conventional"))
  fc <- as.numeric(ef("FC", "Conventional"))
  expect_equal(fc, ec / 42.695 * 1000)
  expect_equal(fc, 338.1, tolerance = 1e-3)

  # diesel Euro I used to crash (duplicated keys); the 2007 row is kept
  expect_error(ef("FC", "I"), NA)
  expect_equal(as.numeric(ef("FC", "I")), 274.85, tolerance = 1e-3)

  # CNG EEV CO2 (was about 51 g/km)
  expect_equal(as.numeric(ef("CO2", "EEV", fuel = "CNG")), 923.9, tolerance = 1e-3)

  key <- c("Fuel", "Segment", "Euro", "Technology", "Pol", "Slope", "Load")
  expect_equal(anyDuplicated(ef_europe_emep_db, by = key), 0L)
})

test_that("ef_europe_emep accepts slope and load vectors (G-20, G-24, G-28)", {
  ef <- function(pollutant, speed, slope = 0, load = 0.5){
    suppressMessages(
      ef_europe_emep(speed = units::set_units(speed, "km/h")
                     , veh_type = "Ubus Std 15 - 18 t"
                     , euro = "V"
                     , pollutant = pollutant
                     , slope = slope
                     , load = load)
    )$EF[[1]]
  }
  
  # vectors with repeated values used to crash; they equal element-wise calls
  speed <- c(20, 30, 40, 50, 15, 60)
  slope <- c(0, 0.02, 0, 0.02, -0.06, 0.06)
  load <- c(0.5, 0.5, 1, 0, 0.5, 1)
  for(p in c("NOx", "FC")){
    vec <- as.numeric(ef(p, speed, slope, load))
    one <- vapply(seq_along(speed)
                  , function(k) as.numeric(ef(p, speed[k], slope[k], load[k]))
                  , numeric(1))
    expect_equal(vec, one)
  }
  
  # CH4 exists only at slope 0 / load 0.5: that value is used, with a message
  expect_message(
    ef_europe_emep(speed = units::set_units(30, "km/h"), veh_type = "Ubus Std 15 - 18 t"
                   , euro = "V", pollutant = "CH4", slope = 0.02)
    , "only at slope 0"
  )
  expect_equal(ef("CH4", 30, slope = 0.02), ef("CH4", 30))
  
  # slope and load outside the EMEP/EEA grid are errors
  expect_error(ef("NOx", 30, slope = 0.03), class = "gtfs2emis_error")
  expect_error(ef("NOx", 30, load = 0.3), class = "gtfs2emis_error")
})

test_that("ef_europe_emep uses the EF row of the requested slope and load (G-20)", {
  # known value: EMEP/EEA 2019 hot-exhaust equation (Function_ID "2019_1"),
  # EF = (a V^2 + b V + c + d / V) / (e V^2 + f V + g) * (1 - RF) * k,
  # with the coefficients of the database row at slope 0.06 and load 1
  row <- ef_europe_emep_db[Pol == "NOx" & Fuel == "D" & Segment == "Ubus Std 15 - 18 t" &
                             Euro == "V" & Technology == "SCR" & Slope == 0.06 & Load == 1]
  expect_equal(nrow(row), 1L)
  expect_equal(row$Function_ID, "2019_1")
  v <- 30
  known <- with(row, (Alpha * v^2 + Beta * v + Gamma + Delta / v) /
                  (Epsilon * v^2 + Zita * v + Hta) * (1 - RF) * k)
  ef <- function(slope, load){
    as.numeric(ef_europe_emep(speed = units::set_units(c(v, v), "km/h")
                              , veh_type = "Ubus Std 15 - 18 t", euro = "V"
                              , pollutant = "NOx", slope = slope, load = load)$EF[[1]])
  }
  res <- ef(slope = c(0.06, 0), load = c(1, 0.5))
  expect_equal(res[1], known, tolerance = 1e-6)
  expect_false(isTRUE(all.equal(res[1], res[2])))
})
