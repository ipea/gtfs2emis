#' @title
#' Transport model
#'
#' @description
#'  This function converts a public transport data set in GTFS format into a
#'  GPS-like table with the space-time positions and speeds of public transport
#'  vehicles. The function also allow users to set the spatial resolution of the
#'  output and to adjust the speed of public transport vehicles given a
#'  `min_speed` and `max_speed` range.
#'
#' @param gtfs_data A path to a GTFS file or a GTFS data organized as a list of
#'        `data.tables` created with `gtfstools::read_gtfs()`.
#' @param min_speed numeric (in km/h) or a speed units value. Minimum speed to
#'        be considered as valid. Values below minimum speed will be updated
#'        according to the `new_speed` parameter, which can affect the arrival
#'        and  departure times of vehicles at  transit stops. Defaults to `2`
#'        km/h.
#' @param max_speed numeric (in km/h) or a speed units value. Maximum speed to
#'        be considered as valid. Values above maximum speed will be  updated
#'        according to the `new_speed` parameter, which can affect the arrival
#'        and departure times of vehicles at transit stops. Defaults to `80`
#'        km/h.
#' @param new_speed numeric (in km/h) or a speed units value. Speed value used
#'        to replace the speeds that fall outside the `min_speed` and `max_speed`
#'        range or which are missing from the GTFS input. When `new_speed = NULL`
#'        (the default), the function uses the average speed of the entire GTFS
#'        data feed.
#' @param parallel This argument is deprecated and ignored. Please use argument
#'         ncores instead.
#' @param ncores Number of threads used. Defaults to 2. If \code{Inf}, it uses
#'        all threads available, as given by \code{data.table::getDTthreads()}.
#' @param spatial_resolution The spatial resolution in meters. Defaults to `100`.
#'        The function only creates points in order to guarantee that the
#'        maximum distance between two consecutive points will be at most the
#'        `spatial_resolution` value. If a given GTFS shape_id has two
#'        consecutive points with a distance smaller than the spatial resolution,
#'        the algorithm will not remove such points.
#' @param output_path Output file path. As default, the output is returned when gtfs2gps
#'        finishes. When this argument is set, each shape is saved into a txt file
#'        within filepath, named after its \code{shape_id}. Characters that can't be
#'        in a file name on some systems (such as \code{/}, \code{:} or \code{*}) and
#'        \code{\%} are written as \code{\%XX}, their hexadecimal code, so \code{utils::URLdecode()} gives the id back
#'        (e.g. \code{"a/b"} is saved as \code{a\%2Fb.txt}). In this case, no output
#'        is returned. See argument compress for another option.
#' @param continue Argument that can be used only with filepath. When TRUE, it
#'        skips processing the shape identifiers that were already saved into
#'        files. It is useful to continue processing a GTFS file that was stopped
#'        for some reason. Default value is `FALSE`.
#'
#' @return An `sf` object (class `c("sf", "data.frame")`) with one LINESTRING
#'         per segment between consecutive stops, or `NULL` when `output_path`
#'         is provided (the outputs are then saved as files in `output_path`).
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
  parallel = TRUE,
  ncores = 2,
  spatial_resolution = 100,
  output_path = NULL,
  continue = FALSE
) {
  # check if required fields and files exist  ----
  assert_character(output_path, len = 1, null.ok = TRUE)
  if (is.character(output_path)) {
    assert_directory_exists(output_path)
  }
  assert_numeric(
    min_speed,
    lower = 2,
    finite = TRUE,
    null.ok = TRUE,
    any.missing = FALSE
  )
  assert_numeric(
    max_speed,
    lower = 3,
    finite = TRUE,
    null.ok = TRUE,
    any.missing = FALSE
  )
  assert_numeric(
    new_speed,
    lower = 1,
    finite = TRUE,
    null.ok = TRUE,
    any.missing = FALSE
  )
  assert_true(min_speed < max_speed, .var.name = "min_speed < max_speed")

  assert_integerish(
    ncores,
    lower = 1,
    upper = data.table::getDTthreads(),
    null.ok = FALSE
  )

  assert_logical(continue, null.ok = FALSE, any.missing = FALSE)

  # Read GTFS ------------

  if (is.character(gtfs_data)) {
    city_gtfs <- gtfs2gps::read_gtfs(gtfszip = gtfs_data, quiet = TRUE)
  } else {
    city_gtfs <- data.table::copy(gtfs_data)
  }

  # number of cores
  if (is.null(ncores)) {
    ncores <- parallelly::availableCores(omit = 1)
    cli::cli_inform('Using {ncores} CPU cores')
  }

  # Fix GTFS speed ------------

  city_gtfs <- gtfstools::remove_duplicates(city_gtfs)
  city_gtfs <- gtfstools::remove_unused_ids(city_gtfs)

  city_gtfs <- gtfstools::set_min_speed(gtfs = city_gtfs, min_speed = min_speed)
  city_gtfs <- gtfstools::set_max_speed(gtfs = city_gtfs, max_speed = max_speed)

  # gtfs2gps ------------
  temp_gps <- gtfs2gps::gtfs2gps(
    gtfs_data = city_gtfs,
    spatial_resolution = spatial_resolution,
    ncores = ncores
  )

  # GPS as Sf_Linestring ------
  # Converting a GPS-like data.table to a LineString Simple Feature (sf)
  temp_gps_sf <- gtfs2gps::gps_as_sflinestring(gps = temp_gps)
  temp_gps_sf$dist <- units::set_units(temp_gps_sf$dist, "km")

  if (is.null(output_path)) {
    return(temp_gps_sf)
  } else {
    # create dir
    suppressWarnings(dir.create(output_path))
    saveRDS(object = temp_gps_sf, file = output_path)
    return(NULL)
  }
}
