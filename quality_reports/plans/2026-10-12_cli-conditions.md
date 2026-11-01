# Plan: migrate all user-facing conditions to cli

**Status:** COMPLETED (2026-10-13), not committed · · adversarial review converged (Minimalist + Skeptic APPROVE, round 2) · **Branch:** `cli-conditions`

## Context

gtfs2emis raises conditions in two ways today:
- 37 base calls in `R/`: 26 `stop()` and 11 `message()`.
- About 180 checkmate assertions: 167 `checkmate::assert_*()` calls across 13 types, 13 `checkmate::assert(..., combine =)` combos, and one `checkmate::expect_class()`.

There are no `warning()`, `stopifnot()`, `print()` or `cat()` calls. The user wants every message, warning and error to go through cli. That gives consistent formatting, the exported function's name in the error header, and one package error class that callers can catch.

Decisions already taken:
- **checkmate stays.** It still does the checks, and failures are re-thrown through cli.
- **This lands before the audit fixes,** so those fixes write their conditions in cli from the start.

## Scope

**In scope:** every `stop()`/`message()` in `R/`, and every checkmate call that throws.

**Out of scope:** behaviour changes.
- No condition changes type. A message stays a message. Whether the EMEP tech-fallback notes should become warnings is decided in the audit fixes.
- No new validation. The no-op `checkmate::check_true()` calls in `emi_europe_emep_wear.R` are left to audit #23.
- Messages keep the same information. Only the markup changes, and cli collapses repeated whitespace.

Also out of scope: test wording, vignettes, README, `data-raw/`.

## Approach

### 1. Dependencies (DESCRIPTION)
- Imports: add `cli (>= 3.4.0)` and `rlang (>= 1.0.0)`.
- rlang has to be in Imports because `cli_abort()` uses rlang (cli only Suggests it), and we call `rlang::caller_env()` / `rlang::current_env()`.
- Suggests: unchanged.
- R (>= 3.6) is compatible with both.

### 2. New file `R/conditions.R` (internal, `@noRd`)

```r
# Internal cli wrappers around checkmate. Each assert_<type>() has the same
# signature as checkmate::assert_<type>() plus `call`, and throws a cli error of
# class "gtfs2emis_error". `msg` is always interpolated as a value, never used as
# a format string, because checkmate messages contain braces.
abort_arg <- function(var_name, msg, call) {
  bullets <- stats::setNames(sprintf("{msg[[%d]]}", seq_along(msg)), rep("x", length(msg)))
  cli::cli_abort(c("Invalid argument {.arg {var_name}}.", bullets),
                 class = "gtfs2emis_error", call = call)
}

make_assert <- function(check_name) {
  force(check_name)
  function(x, ..., .var.name = checkmate::vname(x), call = rlang::caller_env()) {
    res <- getExportedValue("checkmate", check_name)(x, ...)
    if (!isTRUE(res)) abort_arg(.var.name, res, call)
    invisible(x)
  }
}
assert_vector <- make_assert("check_vector")
# ... one line for each of the 13 types in use: choice, character, numeric, class,
# logical, list, string, integerish, file_exists, directory_exists, data_frame, true

# Replaces checkmate::assert(..., combine =). Same signature; .var.name is required.
assert_checks <- function(..., combine = "or", .var.name, call = rlang::caller_env()) {
  if (missing(.var.name)) cli::cli_abort("Internal: {.fn assert_checks} needs {.arg .var.name}.")  # developer guard
  res <- list(...)
  ok <- vapply(res, isTRUE, logical(1))
  if (if (combine == "or") any(ok) else all(ok)) return(invisible(TRUE))
  abort_arg(.var.name, unlist(res[!ok]), call)
}
```

Notes:
- Inside `R/`, a bare `assert_*()` means one of these wrappers. Every external call still uses `pkg::fun`.
- **Caller header.** `call = rlang::caller_env()` names the exported function only when the wrapper is called directly from its body. Errors raised inside `lapply`/closure bodies would otherwise show `FUN()`. In those cases (step 4), the exported function captures `call <- rlang::current_env()` at the top and passes `call = call`.
- **Known limitation.** When an exported function calls another exported function (`emission_model()` → `ef_*()`, `emis_grid()` → `emis_summary()`), the header names the inner one. That is acceptable.

### 3. Rewriting the checkmate calls (mechanical, then hand-checked)

1. `checkmate::assert_` → `assert_`. This is one token per call, so formatting is untouched.
2. `checkmate::assert(` → `assert_checks(`. Add an explicit `.var.name =` to each of the 13 combos. The mixed combo at `emis_grid.R:82` (`emi_list$tp_model` + `time_resolution`) is split into two calls so that each is named correctly.
3. `checkmate::expect_class(...)` in `emis_summary.R:110` → `assert_class(...)`. This also removes the hidden runtime dependency on testthat (audit #15). Add `.var.name = "emi_list$emi"` and `call = call` there.
4. Add a hand-written `.var.name` wherever `vname()` would print the wrong thing:
   - **Literal or expression first argument.** For example, `assert_choice("emi", names(emi_list))` becomes `.var.name = "emi_list"`. The same applies to `assert_true(min_speed < max_speed)`. Sites: `emis_summary.R:87,88,95`, `multiply_ef.R:38`, `ef_scaled_euro.R:94`, `transport_model.R:92`.
   - **Loop variables, about 30 sites** of the form `for (i in pollutant) assert_choice(i, …)`. Each gets `.var.name = "pollutant"` (or the relevant vector). Examples: `ef_europe_emep.R:114`, `fuel_correction.R:29,33,37`, `ef_usa_emfac.R:57,66`.
   - Find sites with `grep -nE 'assert_\w+\(\s*["(]'` and `grep -nE 'for\s*\(\s*\w+ in .*\)\s*(checkmate::)?assert_'`.

### 4. Hand conversion of the 37 base calls

| Pattern | Becomes |
|---|---|
| Length, units or CRS `stop()`s in `ef_*`, `emi_europe_emep_wear`, `emis_grid`, `emis_summary`, `emis_to_dt`, `multiply_ef`, `emission_model` | `cli::cli_abort(c("<problem, with {.arg}>", "x"/"i" = ...), class = "gtfs2emis_error")` |
| "No available emission factor…" (`ef_europe_emep.R:267`, `ef_usa_moves.R:112`, `ef_usa_emfac.R:105`) | `cli::cli_abort()` with one `"*"` bullet per key field, an `"i"` bullet pointing to the dataset, and `class = c("gtfs2emis_missing_ef", "gtfs2emis_error")`. This is the only sub-class, because it is the one users may want to catch. The MOVES message still names `ef_usa_emfac_db`; that is fixed in audit #17 |
| `message()`: EMEP tech fallback ×5, "Using N CPU cores" ×2, "Writing output…", "Constant emission factor…" | `cli::cli_inform()`. The `"\n "` second sentences of the EMEP notes become `"i"` bullets |
| `print_emissions()` in `emis_grid.R` | Same text via `cli::cli_inform()`, with values interpolated |

- **Errors raised inside `lapply`/closures need `call = call`.** The affected exported functions capture `call <- rlang::current_env()` at the top. Sites: `ef_europe_emep.R:267`, `ef_usa_emfac.R:105`, `ef_usa_moves.R:112`, `ef_scaled_euro.R:164,167`, `emis_summary.R:110,113`, `multiply_ef.R:51,54,58`, plus any `assert_*()` inside a closure.
- **`quiet` is unchanged.** The existing `if(!quiet)` guards and `suppressMessages()` keep working: `cli_inform()` signals a message condition and writes to stderr.
- **Inside furrr workers,** conditions keep their class across the future boundary. The header shows the worker function, which is acceptable.

### 5. Tests: new `tests/testthat/test_conditions.R`

The suite stays on testthat edition 2, and no snapshots are used. The file covers:
- A wrapper passes valid input through and aborts with class `gtfs2emis_error` and the argument name.
- `assert_checks()`: `"or"` passes when one check passes, and gives one `x` bullet per failure. `"and"` fails on any failure.
- A brace-containing checkmate message is rendered literally.
- A loop-site argument is named by its `.var.name` (`pollutant`, not `i`).
- An invalid `pollutant` in `ef_europe_emep()` gives `expect_error(class = "gtfs2emis_error", regexp = "pollutant")`.
- **Header check:** the wrong-speed-units error and the missing-EF error (class `gtfs2emis_missing_ef`) are tested as `e <- expect_error(..., class = ...)` with `expect_identical(e$call[[1]], quote(ef_europe_emep))`. This proves the header names the exported function, not `FUN()`.

Existing tests are unaffected: all 64 `expect_error()` calls are bare, with no `regexp` and no `class`.

### 6. Docs and workflow
- **NEWS:** add a "development version" bullet: "Errors and messages now use {cli}; all errors have class `gtfs2emis_error`, and missing emission-factor combinations have class `gtfs2emis_missing_ef`."
- **`.claude/rules/r-package-conventions.md` A4:** replace "keep base conditions" with the cli rules: wrappers, the class, brace safety (never a dotted name such as `{.var.name}` inside `{}`), `call = call` for every `cli_abort()`/`assert_*()` inside a closure, and `.var.name` for loop and literal arguments. The other workflow files point to A4.

## Files
- `DESCRIPTION`
- new `R/conditions.R`
- the 14 `R/` files that raise conditions
- new `tests/testthat/test_conditions.R`
- `NEWS.md`
- the A4 rule

`NAMESPACE` and `man/` are unchanged, because the helpers are `@noRd` and not exported.

## Verification
1. `grep -nE '\b(stop|warning|message)\(|checkmate::(assert|expect)' R/*.R` returns no code hits. 
2. `grep -nE 'assert_\w+\(\s*["(]'`, `grep -n 'assert_true('` and the loop grep: every hit has a `.var.name`.
3. `devtools::document()` shows no drift apart from DESCRIPTION.
4. `devtools::test()` gives no new failures. The 2 tests that fail only with the dev gtfs2gps (audit #8) fail the same way before and after.
5. `emission_model(quiet = TRUE)` and `emis_grid(quiet = TRUE)` print nothing. With `quiet = FALSE` they print the same information.
6. `devtools::check(document = FALSE, args = "--as-cran")` gives 0 errors, 0 warnings and no "Imports not used" NOTE.
7. Review loop: the correctness lens and `r-package-reviewer` on the diff.
