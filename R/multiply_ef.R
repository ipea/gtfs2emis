#' @title 
#' Multiply emission factors by distances 
#'
#' @description 
#' Calculate hot exhaust emissions by multiplying emission factors by distances 
#' weighted by fleet composition profile.
#'
#' @param fleet_composition vector; Fleet composition, which is a distribution 
#'        of fleet based on frequency. If there is only one, 'fleet_composition' 
#'        is 1.0.
#' @param dist units ('km'); Length of each link in km.
#' @param ef list or data.table;	Emission factors.
#' @param aggregate logical; if TRUE (default) emissions are aggregated by 
#'        pollutant.
#' @param prefix character; Add prefix into emissions names. Missing parameter 
#'        (default) means empty prefix.
#' @template as_list
#' 
#' @return units ('g'); emissions per link.
#' 
#' @keywords internal
multiply_ef <- function(fleet_composition, dist, ef, aggregate = TRUE, prefix = NULL, as_list = TRUE){
  call <- rlang::current_env()  # header for conditions raised inside closures
  
  # check ----
  # fleet_composition
  assert_vector(fleet_composition,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(fleet_composition,any.missing = FALSE,min.len = 1,lower = 0,upper = 1)
  # dist
  assert_vector(dist,any.missing = FALSE,min.len = 1,null.ok = FALSE)
  assert_numeric(dist,any.missing = FALSE,min.len = 1)
  assert_class(dist,"units")
  if(!has_units(dist, "km")){
    cli::cli_abort(c("{.arg dist} must be in {.val km}."
                     , "x" = "It has units {.val {units::deparse_unit(dist)}}.")
                   , class = "gtfs2emis_error")
  }
  # ef
  # check if its a list
  if(inherits(x = ef,what = "list")){
    assert_choice("EF",names(ef),null.ok = FALSE, .var.name = "ef")
    tmpEf <- ef$EF
  }else{
    tmpEf <- ef
  }
  # check if ef is constant
  if(length(tmpEf[[1]]) == 1){
    cli::cli_inform("Constant emission factor along the route")
  }
  
  # units
  lapply(seq_along(tmpEf), function(i){ # i = 1
    if(!is(tmpEf[[i]], "units")){
      cli::cli_abort(c("{.arg ef} must have class {.cls units} in {.val g/km}."
                       , "i" = "See the {.pkg units} package.")
                     , class = "gtfs2emis_error", call = call)
    }
    if(!has_units(tmpEf[[i]], "g km-1")){
      cli::cli_abort("{.arg ef} must have units {.val g/km}."
                     , class = "gtfs2emis_error", call = call)
    }
    # check 'tmpEf' length with veh
    if(length(tmpEf[[i]]) != 1 & length(tmpEf[[i]]) != length(dist)){
      cli::cli_abort("{.arg ef} column {.val {names(tmpEf[i])}} must have the same length as {.arg dist}."
                     , class = "gtfs2emis_error", call = call)
    }
  })
  
  # extract single pollutants----
  
  if(is(ef, "list")){
    single_pol <- unique(ef$pollutant)
  }else{
    # verify how many pollutants 'ef' data has based on names(ef)
    m <- regexpr(pattern = "\\_", text = colnames(ef), fixed = FALSE)
    # get unique pollutants
    single_pol <- sapply(regmatches(x = colnames(ef), m = m, invert = TRUE), function(i){i[[1]]})
    single_pol <- unique(single_pol)
  }
  
  # match 'veh' size based on different pollutant----
  
  fleet_composition <- rep(fleet_composition, length(single_pol))
  
  # emissions----
  
  emi <- lapply(seq_along(tmpEf), function(i){ # i = 1 
    temp_emis <- tmpEf[[i]] * fleet_composition[[i]] * dist
    return(temp_emis)
  })
  
  emi <- do.call(cbind, emi) 
  emi <- data.table::as.data.table(emi)
  colnames(emi) <- colnames(tmpEf)
  
  #
  # aggregate condition----
  #
  
  if(aggregate){
    # aggregate by single pollutant
    lapply(single_pol, function(i){ # i = single_pol[1]
      colnames_temp <- colnames(emi)[colnames(emi) %like% paste0(i, "_")]
      names_newcol <- paste0(i, "_total")
      emi[, (names_newcol) := rowSums(.SD), .SDcols = colnames_temp]
    })
    # keep only total_emissions
    colnames_avg <- colnames(emi)[colnames(emi) %like% "_total"]
    emi <- emi[, .SD, .SDcols = colnames_avg]
  }
  
  # prefix condition ----
  
  if(missing(prefix) == FALSE){
    colnames(emi) <- paste0(prefix, "_", colnames(emi))
  }
  
  # units conversion ----
  
  emi <- emi[, lapply(.SD, units::set_units,'g')]
  
  # export ---
  
  if(as_list & inherits(x = ef,what = "list")){
    ef$emi <- emi
    return(ef)
  }else{
    return(emi)
  }
  
}
