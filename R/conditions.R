# Internal cli wrappers around checkmate.
#
# Each assert_<type>() has the same signature as checkmate::assert_<type>()
# plus `call`, and throws a cli error of class "gtfs2emis_error" whose header
# names the calling (exported) function. Inside lapply()/closures, pass
# `call = call` where `call <- rlang::current_env()` was captured at the top of
# the exported function, otherwise the header reads `FUN()`.
#
# checkmate messages contain braces (e.g. "Must be element of set {'a','b'}"),
# so they are always interpolated as values, never used as a cli format string.

abort_arg <- function(var_name, msg, call, lead = NULL) {
  bullets <- stats::setNames(sprintf("{msg[[%d]]}", seq_along(msg))
                             , rep("x", length(msg)))
  if (!is.null(lead)) bullets <- c("i" = lead, bullets)
  cli::cli_abort(c("Invalid argument {.arg {var_name}}.", bullets)
                 , class = "gtfs2emis_error"
                 , call = call)
}

make_assert <- function(check_name) {
  force(check_name)
  function(x, ..., .var.name = checkmate::vname(x), call = rlang::caller_env()) {
    res <- getExportedValue("checkmate", check_name)(x, ...)
    if (!isTRUE(res)) abort_arg(.var.name, res, call)
    return(invisible(x))
  }
}

assert_character        <- make_assert("check_character")
assert_choice           <- make_assert("check_choice")
assert_class            <- make_assert("check_class")
assert_data_frame       <- make_assert("check_data_frame")
assert_directory_exists <- make_assert("check_directory_exists")
assert_file_exists      <- make_assert("check_file_exists")
assert_integerish       <- make_assert("check_integerish")
assert_list             <- make_assert("check_list")
assert_logical          <- make_assert("check_logical")
assert_numeric          <- make_assert("check_numeric")
assert_string           <- make_assert("check_string")
assert_true             <- make_assert("check_true")
assert_vector           <- make_assert("check_vector")

# Replacement for checkmate::assert(..., combine =). `.var.name` is required.
# Unlike checkmate::assert(), all checks are evaluated (no short-circuit), so a
# check must not depend on an earlier one having passed.
assert_checks <- function(..., combine = c("or", "and"), .var.name, call = rlang::caller_env()) {
  if (missing(.var.name)) {
    cli::cli_abort("Internal: {.fn assert_checks} needs {.arg .var.name}."
                   , class = "gtfs2emis_error")
  }
  combine <- match.arg(combine)
  res <- list(...)
  ok <- vapply(res, isTRUE, logical(1))
  passed <- if (combine == "or") any(ok) else all(ok)
  if (!passed) {
    abort_arg(.var.name, unlist(res[!ok]), call
              , lead = if (combine == "or" && sum(!ok) > 1) "One of the following must apply:")
  }
  return(invisible(TRUE))
}
