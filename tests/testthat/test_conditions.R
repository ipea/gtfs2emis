context("conditions")

speed_kmh <- units::set_units(c(20, 30), "km/h")

test_that("assert wrappers pass valid input and abort with a classed cli error", {
  f <- function(n) assert_numeric(n, lower = 0)
  expect_identical(f(1), 1)
  e <- expect_error(f(-1), class = "gtfs2emis_error")
  expect_match(conditionMessage(e), "`n`", fixed = TRUE)
  expect_identical(e$call[[1]], quote(f))
})

test_that("assert_checks() combines with 'or' and 'and'", {
  expect_true(assert_checks(checkmate::check_numeric("a"), checkmate::check_character("a")
                            , combine = "or", .var.name = "x"))
  e <- expect_error(assert_checks(checkmate::check_numeric("a"), checkmate::check_logical("a")
                                  , combine = "or", .var.name = "x")
                    , class = "gtfs2emis_error")
  msg <- conditionMessage(e)
  expect_match(msg, "One of the following must apply", fixed = TRUE)
  expect_match(msg, "'numeric'", fixed = TRUE)
  expect_match(msg, "'logical'", fixed = TRUE)
  expect_error(assert_checks(checkmate::check_character("a"), checkmate::check_numeric("a")
                             , combine = "and", .var.name = "x")
               , class = "gtfs2emis_error")
  expect_error(assert_checks(checkmate::check_numeric("a"))
               , class = "gtfs2emis_error", regexp = "needs")
})

test_that("checkmate messages with braces are rendered literally", {
  e <- expect_error(assert_choice("z", c("a", "{x}")), class = "gtfs2emis_error")
  expect_match(conditionMessage(e), "{'a','{x}'}", fixed = TRUE)
})

test_that("loop-validated arguments are named by .var.name, not the loop variable", {
  e <- expect_error(ef_europe_emep(speed_kmh, "Ubus Std 15 - 18 t", "IV", c("NOx", "banana"))
                    , class = "gtfs2emis_error")
  expect_match(conditionMessage(e), "`pollutant`", fixed = TRUE)
  expect_false(grepl("`i`", conditionMessage(e), fixed = TRUE))
})

test_that("errors name the exported function in their call, also inside closures", {
  # top-level check
  e <- expect_error(ef_europe_emep(units::set_units(c(5, 8), "m/s"), "Ubus Std 15 - 18 t", "IV", "NOx")
                    , class = "gtfs2emis_error")
  expect_identical(e$call[[1]], quote(ef_europe_emep))

  # Raised inside lapply() with call = rlang::current_env(). These combinations
  # are chosen because the databases have no row for them (no CNG Euro IV SCR in
  # EMEP; no CNG before model year 1988 in EMFAC). If the data change, pick
  # another missing combination.
  e <- expect_error(suppressMessages(
    ef_europe_emep(speed_kmh, "Ubus Std 15 - 18 t", "IV", "NOx", fuel = "CNG"))
    , class = "gtfs2emis_missing_ef")
  expect_identical(e$call[[1]], quote(ef_europe_emep))

  e <- expect_error(ef_usa_emfac("CO", 2019, "CNG", 1985, speed_kmh)
                    , class = "gtfs2emis_missing_ef")
  expect_identical(e$call[[1]], quote(ef_usa_emfac))

  # wrong EF units, raised inside lapply() in multiply_ef()
  bad_ef <- data.frame(a = units::set_units(1, "g/m"))
  e <- expect_error(suppressMessages(
    multiply_ef(1, units::set_units(c(1, 2), "km"), bad_ef))
    , class = "gtfs2emis_error")
  expect_identical(e$call[[1]], quote(multiply_ef))
})

test_that("informative messages are cli message conditions", {
  expect_message(ef_europe_emep(speed_kmh, "Ubus Std 15 - 18 t", "III", "NOx", tech = "SCR")
                 , "Technology entry")
  expect_silent(suppressMessages(
    ef_europe_emep(speed_kmh, "Ubus Std 15 - 18 t", "III", "NOx", tech = "SCR")))
})
