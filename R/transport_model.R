#' @title
#' Transport model
#'
#' @description
#'  This function converts a public transport data set in GTFS format into
#'  road segments between consecutive stops of each trip, with their times,
#'  distances and speeds, using the gtfs2gps package. The function also allows users to
#'  set the spatial resolution of the output and to keep the speed of public
#'  transport vehicles within a `min_speed` and `max_speed` range.
#'
#' @param gtfs_data A path to a GTFS file or a GTFS data organized as a list of
#'        `data.tables` created with `gtfstools::read_gtfs()`.
#' @param min_speed numeric (in km/h) or a speed units value. Minimum valid
#'        speed, at least 2 km/h. Defaults to `2` km/h. Stop times are first
#'        adjusted with [gtfstools::set_min_speed()], which can change the
#'        arrival and departure times of vehicles at transit stops. Segment
#'        speeds that are still below `min_speed` are then set to `min_speed`.
#'        The segment's duration becomes its distance divided by the new speed,
#'        and the later times of the trip are shifted by the difference (each
#'        trip keeps its first departure). Durations are rounded to whole
#'        seconds, so a very short segment (under about 11 m at 80 km/h) can
#'        keep 0 s.
#' @param max_speed numeric (in km/h) or a speed units value. Maximum valid
#'        speed, at least 3 km/h. Defaults to `80` km/h. As for `min_speed`,
#'        stop times are first adjusted with [gtfstools::set_max_speed()], and
#'        segment speeds still above `max_speed` are set to `max_speed`, with
#'        the trip's times shifted in the same way.
#' @param new_speed numeric (in km/h) or a speed units value, between
#'        `min_speed` and `max_speed`. Speed used for segments without a speed;
#'        the trip's times are shifted as for `min_speed`. When
#'        `new_speed = NULL` (the default), the function uses the average speed
#'        (total distance / total time) of the trips of the same `shape_id`,
#'        after capping, or of the whole feed if the shape has none.
#' @param parallel **Deprecated.** This argument is ignored, and using it gives
#'        a warning. Use `ncores` instead.
#' @param ncores Number of threads used. Defaults to 2. If \code{Inf}, it uses
#'        all threads available, as given by \code{data.table::getDTthreads()}.
#'        Values above that number are reduced to it.
#' @param spatial_resolution The spatial resolution in meters. Defaults to `100`.
#'        The function only creates points in order to guarantee that the
#'        maximum distance between two consecutive points will be at most the
#'        `spatial_resolution` value. If a given GTFS shape_id has two
#'        consecutive points with a distance smaller than the spatial resolution,
#'        the algorithm will not remove such points.
#' @param output_path character. A directory path. If `NULL` (default), the
#'        output is returned. Otherwise, the output of each `shape_id` is saved
#'        in this directory as an `.rds` file named after its `shape_id`, and
#'        nothing is returned. Characters that can't be in a file name on some
#'        systems (such as \code{/}, \code{:} or \code{*}) and \code{\%} are
#'        written as \code{\%XX}, their hexadecimal code, so
#'        \code{utils::URLdecode()} gives the id back (e.g. \code{"a/b"} is saved
#'        as \code{a\%2Fb.rds}). The whole feed is still processed in memory.
#'        [emission_model()] reads every `.rds` file in this directory, so it
#'        should not contain files from other runs.
#' @param continue **Deprecated.** This argument is ignored, and using it gives
#'        a warning. The whole feed is processed at once.
#'
#' @return An `sf` object (class `c("sf", "data.frame")`, CRS 4326) with one
#'         LINESTRING per segment between consecutive stops, from the first to
#'         the last stop of each trip, or `NULL` when `output_path` is provided
#'         (the outputs are then saved as files in `output_path`). Its columns
#'         are:
#'
#' - `shape_id`, `trip_id`, `route_type`, `trip_number`: the trip.
#'   For trips in `frequencies.txt`, `trip_id` gets a suffix for each
#'   departure (e.g. `"1054020_1"`, `"1054020_2"`);
#' - `from_stop_id`, `to_stop_id`, `stop_sequence`: the segment's stops;
#' - `from_timestamp`, `to_timestamp` (class `ITime`), and `timestamp`,
#'   equal to `from_timestamp`;
#' - `dist` (km) and `speed` (km/h) of the segment, and `cumdist` (m) and
#'   `cumtime` (s), cumulative along the trip, all as `units` objects;
#' - `geometry`.
#'
#' @family Core function
#'
#' @examples
#' \donttest{
#' if (requireNamespace("gtfstools", quietly=TRUE)) {
#'
#' # read GTFS
#' gtfs_file <- system.file("extdata/bra_cur_gtfs.zip", package = "gtfs2emis")
#' gtfs <- gtfstools::read_gtfs(gtfs_file)
#'
#' # keep a single trip_id to speed up this example
#' gtfs_small <- gtfstools::filter_by_trip_id(gtfs, trip_id ="4451136")
#'
#' # run transport model
#' tp_model <- transport_model(
#'   gtfs_data = gtfs_small,
#'   min_speed = 2,
#'   max_speed = 80,
#'   new_speed = 20,
#'   spatial_resolution = 100,
#'   ncores = 2)
#'
#' head(tp_model)
#'
#'   }
#'}
#' @export
transport_model <- function(
  gtfs_data,
  min_speed = 2,
  max_speed = 80,
  new_speed = NULL,
  parallel = NULL,
  ncores = 2,
  spatial_resolution = 100,
  output_path = NULL,
  continue = NULL
) {
  call <- rlang::current_env() # header for conditions raised inside handlers

  # deprecated arguments ----
  for (arg in c("parallel", "continue")[c(
    !missing(parallel),
    !missing(continue)
  )]) {
    cli::cli_warn(
      c(
        "!" = paste0(
          "The {.arg {arg}} argument of {.fn transport_model} is deprecated ",
          "and is ignored."
        ),
        "i" = if (arg == "parallel") {
          "Use {.arg ncores} to set the number of threads instead."
        } else {
          "The whole feed is processed at once."
        }
      ),
      class = "gtfs2emis_deprecated"
    )
  }

  # speeds in km/h ----
  to_kmh <- function(x) {
    if (inherits(x, "units")) {
      x <- as.numeric(units::set_units(x, "km/h"))
    }
    return(x)
  }
  min_speed <- to_kmh(min_speed)
  max_speed <- to_kmh(max_speed)
  new_speed <- to_kmh(new_speed)

  # check if required fields and files exist  ----
  assert_character(output_path, len = 1, null.ok = TRUE)
  if (is.character(output_path)) {
    assert_directory_exists(output_path)
  }
  assert_number(min_speed, lower = 2, finite = TRUE)
  assert_number(max_speed, lower = 3, finite = TRUE)
  assert_true(min_speed < max_speed, .var.name = "min_speed < max_speed")
  assert_number(
    new_speed,
    lower = min_speed,
    upper = max_speed,
    finite = TRUE,
    null.ok = TRUE
  )

  # number of threads
  assert_number(ncores, lower = 1)
  if (is.infinite(ncores)) {
    ncores <- data.table::getDTthreads()
  }
  assert_integerish(ncores, lower = 1)
  ncores <- min(ncores, data.table::getDTthreads())

  # Read GTFS ------------

  if (is.character(gtfs_data)) {
    city_gtfs <- gtfstools::read_gtfs(path = gtfs_data)
  } else {
    city_gtfs <- data.table::copy(gtfs_data)
  }

  # Fix GTFS speed ------------

  city_gtfs <- gtfstools::remove_duplicates(city_gtfs)
  city_gtfs <- gtfstools::remove_unused_ids(city_gtfs)

  # fill blank stop times (the schedule's own times are kept), then limit
  # the speeds between stops, so the limits also apply to the filled times
  city_gtfs <- gtfstools::interpolate_stop_times(
    gtfs = city_gtfs,
    overwrite = FALSE
  )
  city_gtfs <- gtfstools::set_min_speed(gtfs = city_gtfs, min_speed = min_speed)
  city_gtfs <- gtfstools::set_max_speed(gtfs = city_gtfs, max_speed = max_speed)

  # gtfs2gps ------------
  temp_gps <- tryCatch(
    gtfs2gps::gtfs2gps(
      gtfs_data = city_gtfs,
      spatial_resolution = spatial_resolution,
      ncores = ncores
    ),
    # condition class of gtfs2gps >= 2.1-4.9000
    gtfs2gps_nothing_converted_error = function(e) {
      cli::cli_abort(
        c(
          "{.pkg gtfs2gps} converted no trip in {.arg gtfs_data}.",
          "i" = "Check that it has trips with a shape and at least two stops."
        ),
        parent = e,
        class = "gtfs2emis_error",
        call = call
      )
    }
  )

  # GPS as Sf_Linestring ------
  # Converting a GPS-like data.table to a LineString Simple Feature (sf)
  temp_gps_sf <- gtfs2gps::gps_as_sflinestring(gps = temp_gps)
  class(temp_gps_sf) <- c("sf", "data.frame")

  # cap out-of-range speeds, fill missing ones, and shift the trips' times
  speed_old <- as.numeric(units::set_units(temp_gps_sf$speed, "km/h"))
  dist_m <- as.numeric(units::set_units(temp_gps_sf$dist, "m"))
  speed <- fill_speed(
    speed = speed_old,
    dist = dist_m,
    min_speed = min_speed,
    max_speed = max_speed,
    new_speed = new_speed,
    group = temp_gps_sf$shape_id
  )
  temp_gps_sf <- retime_segments(temp_gps_sf, dist_m, speed_old, speed)
  temp_gps_sf$speed <- units::set_units(speed, "km/h")
  temp_gps_sf$dist <- units::set_units(temp_gps_sf$dist, "km")

  if (is.null(output_path)) {
    return(temp_gps_sf)
  }

  # one file per shape
  parts <- split(temp_gps_sf, as.character(temp_gps_sf$shape_id))
  file_names <- vapply(
    names(parts),
    utils::URLencode,
    character(1),
    reserved = TRUE,
    repeated = TRUE
  )
  if (anyDuplicated(tolower(file_names))) {
    cli::cli_abort(
      c(
        "Some {.field shape_id} values differ only in upper/lower case.",
        "i" = "Their files in {.arg output_path} would overwrite each other on some systems."
      ),
      class = "gtfs2emis_error"
    )
  }
  for (i in seq_along(parts)) {
    saveRDS(
      object = parts[[i]],
      file = file.path(output_path, paste0(file_names[i], ".rds"))
    )
  }
  return(invisible(NULL))
}

#' Cap out-of-range speeds and fill missing ones
#'
#' @param speed,dist numeric; segment speeds (km/h) and distances (m).
#' @param min_speed,max_speed numeric; valid speed range (km/h). Speeds
#'        outside it, including `Inf`, are set to the nearest limit.
#' @param new_speed numeric or NULL; speed for missing (`NA`) values. If
#'        `NULL`, the average speed (total distance / total time) of the
#'        segments of the same `group` with a speed and a positive distance,
#'        after capping; groups with none use that average over all segments.
#' @param group vector; the group of each segment (the `shape_id`).
#' @param call environment used in error messages.
#' @return numeric; `speed` capped to the range, with missing values filled.
#' @noRd
fill_speed <- function(
  speed,
  dist,
  min_speed,
  max_speed,
  new_speed = NULL,
  group = 1L,
  call = rlang::caller_env()
) {
  miss <- is.na(speed)
  speed[!miss] <- pmin(pmax(speed[!miss], min_speed), max_speed)
  if (!any(miss)) {
    return(speed)
  }
  if (!is.null(new_speed)) {
    speed[miss] <- new_speed
    return(speed)
  }
  ok <- !miss & is.finite(dist) & dist > 0
  if (!any(ok)) {
    cli::cli_abort(
      c(
        "Missing speeds can't be filled: no segment has both a speed and a distance.",
        "i" = "Set {.arg new_speed} to replace them."
      ),
      class = "gtfs2emis_error",
      call = call
    )
  }
  # average speed = total distance / total time
  avg_speed <- function(i) sum(dist[i]) / sum(dist[i] / speed[i])
  group <- rep_len(as.character(group), length(speed))
  feed_avg <- avg_speed(ok)
  for (g in unique(group[miss])) {
    in_g <- group == g
    fill <- if (any(ok & in_g)) avg_speed(ok & in_g) else feed_avg
    speed[miss & in_g] <- fill
  }
  return(speed)
}

#' Shift segment times after their speeds change
#'
#' The duration of each segment whose speed changed (and that has a positive
#' distance and known times) becomes `3.6 * dist / speed_new` seconds. The
#' difference is carried to every later segment of the same trip, so each
#' trip keeps its first departure and its dwell times. Times are wrapped at
#' midnight, as in gtfs2gps. Times are rounded through the cumulative shift,
#' so durations are accurate to about 1 s (a very short segment can keep 0 s).
#'
#' @param x sf; output of `gtfs2gps::gps_as_sflinestring()`, in its row order.
#' @param dist numeric; segment distances (m).
#' @param speed_old,speed_new numeric; segment speeds (km/h) before and after
#'        `fill_speed()`.
#' @return `x` with `from_timestamp`, `to_timestamp`, `timestamp` and
#'         `cumtime` shifted.
#' @noRd
retime_segments <- function(x, dist, speed_old, speed_new) {
  changed <- is.na(speed_old) | speed_old != speed_new
  if (!any(changed)) {
    return(x)
  }
  from <- as.integer(x$from_timestamp)
  to <- as.integer(x$to_timestamp)
  d_old <- (to - from) %% 86400L
  d_new <- d_old
  redo <- changed & is.finite(dist) & dist > 0 & !is.na(d_old)
  d_new[redo] <- 3.6 * dist[redo] / speed_new[redo]
  delta <- d_new - d_old
  delta[is.na(delta)] <- 0

  dt <- data.table::data.table(
    shape_id = x$shape_id,
    trip_id = x$trip_id,
    trip_number = x$trip_number,
    delta = delta
  )
  dt[, cs := cumsum(delta), by = c("shape_id", "trip_id", "trip_number")]
  dt[, cs_prev := c(0, cs[-.N]), by = c("shape_id", "trip_id", "trip_number")]

  x$from_timestamp <- data.table::as.ITime((from + round(dt$cs_prev)) %% 86400L)
  x$to_timestamp <- data.table::as.ITime((to + round(dt$cs)) %% 86400L)
  x$timestamp <- x$from_timestamp
  cumtime <- round(as.numeric(units::set_units(x$cumtime, "s")) + dt$cs, 3)
  x$cumtime <- units::set_units(cumtime, "s")
  return(x)
}
