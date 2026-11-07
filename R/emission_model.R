#' @title Emission model 
#' 
#' @description Estimate hot-exhaust emissions of public transport systems. This
#'              function must be used together with \code{\link{transport_model}}.
#' 
#' @param tp_model sf_linestring object or a character path the to sf_linestring objects.
#'        The `tp_model` is the output from \code{\link{transport_model}}, 
#'        or the path in which the output files from the \code{\link{transport_model}} are saved.
#' @param ef_model character. A string indicating the emission factor model 
#'        to be used. Options include `ef_usa_moves`, `ef_usa_emfac`, `ef_europe_emep`,
#'        `ef_brazil_cetesb`, and `ef_brazil_scaled_euro` (scale `ef_brazil_cetesb()` based
#'        on `ef_scaled_euro()`).
#' @param fleet_data data.frame. A `data.frame` with information the fleet
#'        characteristics. The required columns depend on the
#'        `ef_model` selection. See Details and Examples.
#' @param pollutant character. Vector with one or more pollutants to be estimated.
#'        Example: `c("CO", "CO2", "PM10", "NOx")`. See the documentation to check which 
#'        pollutants are available for each emission factor model (`ef_usa_moves`, `ef_usa_emfac`,
#'        `ef_europe_emep`, or `ef_brazil_cetesb`). With `ef_europe_emep`, energy consumption
#'        ("EC", in MJ/km) is not a mass and cannot be used.
#' @param reference_year numeric. Year of reference considered to calculate the
#'        emissions inventory. Defaults to `2020`. This
#'        argument is only used when the `ef_model`
#'        parameter is `ef_usa_moves` or `ef_usa_emfac`. The reference year is
#'        always taken from this argument, not from a column of `fleet_data`.
#' @param process character; Emission process, classified in "hot_exhaust" (Default),
#'        and wear processes (identified as "tyre","brake" and/or "road" wear). 
#'        Note that wear processes are only available when `ef_model` is
#'        `ef_europe_emep`, and that `"hot_exhaust"` cannot be combined with
#'        wear processes in the same call. Details on wear emissions are presented in
#'        \code{\link{emi_europe_emep_wear}}.
#' @param heightfile character or raster data. The raster file with height data,
#'        or its filepath, used to estimate emissions considering the effect of 
#'        street slope. This argument is used only when `ef_brazil_scaled_euro` or 
#'        `ef_europe_emep` are selected. Default is `NULL`. Details are provided in
#'        \code{\link{slope_class_europe_emep}}.
#' @param parallel **Deprecated.** Using it gives a warning. `parallel = FALSE`
#'        still runs sequentially; any other value is ignored. Use `ncores`
#'        instead.
#' @param ncores Number of parallel R processes used when `tp_model` is a
#'        folder of files (each process loads the installed gtfs2emis).
#'        Defaults to 2; `1` runs sequentially; `Inf` uses all available
#'        cores, as given by `parallelly::availableCores()`, and larger values
#'        are reduced to that number; `NULL` is treated as 2. Not used when
#'        `tp_model` is an `sf` object.
#' @param output_path character. File path where the function output is exported.
#'        If `NULL` (Default), the function returns the output to user. When
#'        `tp_model` is a folder, `output_path` must be a different folder.
#' @param continue logical. Argument that can be used only with output_path When TRUE,
#'        it skips processing the shape identifiers that were already saved into 
#'        files. It is useful to continue processing a GTFS file that was stopped
#'        for some reason. Default value is FALSE.    
#' @param quiet logical. If `TRUE` (Default), messages from the emissions and
#'        emission factor functions are suppressed. Set to `FALSE` to display them.
#' @details The `fleet_data` must be a `data.frame` organized according to the desired
#' `ef_model`. The required columns are organized as follows (see Examples for real
#' data usage).
#' - `veh_type`: character; Bus type, classified according to `ef_model`.
#'             For `ef_europe_emep`, use "Ubus Midi <=15 t","Ubus Std 15 - 18 t",
#'             "Ubus Artic >18 t", "Coaches Std <=18 t" or "Coaches Artic >18 t"; For
#'             `ef_usa_moves` or `ef_usa_emfac`, use "BUS_URBAN_D"; For `ef_brazil_cetesb`
#'             and `ef_brazil_scaled_euro`, use "BUS_URBAN_D", "BUS_MICRO_D",
#'             "BUS_COACH_D" or "BUS_ARTIC_D".
#' - `model_year`: numeric; Model year of vehicle. Required when `ef_usa_moves`,
#'            `ef_usa_emfac`, `ef_brazil_cetesb` or `ef_brazil_scaled_euro` are selected.
#' - `type_name_eu`: character; European bus type, used only when `ef_model` is
#'            `ef_brazil_scaled_euro`. The classes can be "Ubus Midi <=15 t","Ubus Std 15 - 18 t",
#'             "Ubus Artic >18 t", "Coaches Std <=18 t" or "Coaches Artic >18 t".
#' - `tech`: character; After treatment technology. Required only
#'            when `ef_europe_emep` or `ef_brazil_scaled_euro` are selected. Check
#'            `?ef_europe_emep` for details.
#' - `euro`: character; Euro period of vehicle, classified in
#'            "Conventional", "I", "II", "III", "IV", "V", "VI", and "EEV". Required only
#'            when `ef_europe_emep` or `ef_brazil_scaled_euro` are selected. Check
#'            `?ef_europe_emep` for details.
#' - `fuel`: character; Required when `ef_usa_moves`, `ef_usa_emfac`,
#'            `ef_europe_emep` or `ef_brazil_scaled_euro` are selected.
#' - `fleet_composition`: Numeric. Scaled composition of fleet. In most 
#'            cases, the user might not know which vehicles run on each specific routes.
#'            The composition is used to attribute a probability of a specific vehicle to 
#'            circulate in the line. The probability sums one. Required for all emission 
#'            factors selection. 
#'  For `ef_usa_moves` and `ef_usa_emfac`, the year of the emission inventory is
#'  set with the `reference_year` argument; `fleet_data` does not need a
#'  reference year column.
#'
#'  Users can check the [gtfs2emis fleet data vignette](https://ipea.github.io/gtfs2emis/articles/gtfs2emis_fleet_data.html),
#'   for more examples. 
#'  
#'  Based on the input height data, the function returns the slope class between 
#'  two consecutive bus stop positions of a LineString Simple Feature 
#'  (transport model object). The slope is given by the ratio between the height 
#'  difference and network distance from two consecutive public transport stops.
#'  The function classifies the slope into one of the seven categories
#' available on the European Environmental Agency (EEA) database, which is -0.06,
#'  -0.04,-0.02, 0.00, 0.02, 0.04, and 0.06. 
#' @return If `output_path` is `NULL`: when `tp_model` is an `sf` object, a `list`
#'         with emission estimates (`emi`), emission factors (`EF`), the transport
#'         model (`tp_model`) and the fleet and pollutant information; when
#'         `tp_model` is a path, an unnamed `list` with one such list per file.
#'         If `output_path` is provided, `NULL` is returned and the outputs are
#'         saved as `.rds` files in `output_path`.
#' @family Core function
#' @examples
#' \donttest{
#'  if (requireNamespace("gtfstools", quietly=TRUE)) {
#' 
#' # read GTFS
#' gtfs_file <- system.file("extdata/bra_cur_gtfs.zip", package = "gtfs2emis")
#' gtfs <- gtfstools::read_gtfs(gtfs_file) 
#' 
#' # keep a single trip_id to speed up this example
#' gtfs_small <- gtfstools::filter_by_trip_id(gtfs, trip_id ="4451136")
#'   
#' # run transport model
#' tp_model <- transport_model(gtfs_data = gtfs_small,
#'                             min_speed = 2,
#'                             max_speed = 80,
#'                             new_speed = 20,
#'                             spatial_resolution = 100)
#' 
#' # Example using Brazilian emission model and fleet
#' fleet_data_ef_cetesb <- data.frame(veh_type = "BUS_URBAN_D",
#'                                    model_year = 2010:2019,
#'                                    fuel = "D",
#'                                    fleet_composition = rep(0.1,10)
#'                                    )
#'                                    
#' emi_cetesb <- emission_model(
#'                 tp_model = tp_model,
#'                 ef_model = "ef_brazil_cetesb",
#'                 fleet_data = fleet_data_ef_cetesb,
#'                 pollutant = c("CO","PM10","CO2","CH4","NOx")
#'                 )
#'
#' # Example using Brazilian emission factors scaled by the European model
#' fleet_data_scaled_euro <- data.frame(veh_type = "BUS_URBAN_D",
#'                                      type_name_eu = "Ubus Std 15 - 18 t",
#'                                      model_year = c(2010, 2015),
#'                                      euro = c("III", "V"),
#'                                      fuel = "D",
#'                                      tech = c("-", "SCR"),
#'                                      fleet_composition = c(0.4, 0.6)
#'                                      )
#'
#' emi_scaled_euro <- emission_model(
#'                 tp_model = tp_model,
#'                 ef_model = "ef_brazil_scaled_euro",
#'                 fleet_data = fleet_data_scaled_euro,
#'                 pollutant = c("CO","PM10","NOx")
#'                 )
#'
#' # Example using European emission model and fleet
#' fleet_data_ef_europe <- data.frame(  veh_type = c("Ubus Midi <=15 t",
#'                                                   "Ubus Std 15 - 18 t",
#'                                                   "Ubus Artic >18 t")
#'                                    , euro = c("III","IV","V")
#'                                    , fuel = rep("D",3)
#'                                    , tech = c("-","SCR","SCR")
#'                                    , fleet_composition = c(0.4,0.5,0.1))
#'                                    
#' emi_emep <- emission_model(tp_model = tp_model
#'                           , ef_model = "ef_europe_emep"
#'                           , fleet_data = fleet_data_ef_europe
#'                           , pollutant = c("PM10","NOx"))
#' emi_emep_wear <- emission_model(tp_model = tp_model
#'                           , ef_model = "ef_europe_emep"
#'                           , fleet_data = fleet_data_ef_europe
#'                           , pollutant = "PM10"
#'                           , process = c("tyre","road","brake"))
#' raster_cur <- system.file("extdata/bra_cur-srtm.tif", package = "gtfs2emis")
#' emi_emep_slope <- emission_model(tp_model = tp_model
#'                           , ef_model = "ef_europe_emep"
#'                           , fleet_data = fleet_data_ef_europe
#'                           , heightfile = raster_cur
#'                           , pollutant = c("PM10","NOx"))
#'
#' # Fleet data for the US MOVES and EMFAC emission models
#' # (the inventory year is set with the `reference_year` argument)
#' fleet_data_ef_moves <- data.frame(  veh_type = "BUS_URBAN_D"
#'                                   , model_year = 2010:2019
#'                                   , fuel = "D"
#'                                   , fleet_composition = rep(0.1,10))
#'
#' fleet_data_ef_emfac <- data.frame(  veh_type =  "BUS_URBAN_D"
#'                                   , model_year = 2010:2019
#'                                   , fuel = "D"
#'                                   , fleet_composition = rep(0.1,10))
#'
#' # Examples using US MOVES and EMFAC emission models
#' emi_moves <- emission_model(tp_model = tp_model
#'                           , ef_model = "ef_usa_moves"
#'                           , fleet_data = fleet_data_ef_moves
#'                           , pollutant = c("CO","PM10","CO2","CH4","NOx")
#'                           , reference_year = 2020)
#'                           
#' emi_emfac <- emission_model(tp_model = tp_model
#'                           , ef_model = "ef_usa_emfac"
#'                           , fleet_data = fleet_data_ef_emfac
#'                           , pollutant = c("CO","PM10","CO2","CH4","NOx")
#'                           , reference_year = 2020)
#' }
#' }
#' @export
emission_model <- function(  tp_model
                             , ef_model
                             , fleet_data
                             , pollutant
                             , reference_year = 2020
                             , process = "hot_exhaust"
                             , heightfile = NULL
                             , parallel = NULL
                             , ncores = 2
                             , output_path = NULL
                             , continue = FALSE
                             , quiet = TRUE){
  # deprecated arguments ----
  if(!missing(parallel)){
    cli::cli_warn(c("!" = "The {.arg parallel} argument of {.fn emission_model} is deprecated."
                    , "i" = "Use {.arg ncores} instead ({.code ncores = 1} runs sequentially).")
                  , class = "gtfs2emis_deprecated")
    # old code with parallel = FALSE stays sequential
    if(isFALSE(parallel)) ncores <- 1
  }

  # A) Checking inputs -----

  # number of parallel processes (used only when tp_model is a folder)
  if(is.null(ncores)) ncores <- 2
  assert_number(ncores, lower = 1)
  ncores <- min(ncores, parallelly::availableCores())
  assert_integerish(ncores, lower = 1)

  assert_data_frame(fleet_data, null.ok = FALSE)
  assert_vector(pollutant, null.ok = FALSE)
  assert_logical(continue, null.ok = FALSE)
  assert_logical(quiet, null.ok = FALSE)
  assert_numeric(reference_year, lower = 2000, finite = TRUE, any.missing = TRUE)
  assert_checks(
    checkmate::check_class(tp_model, classes = c("sf", "data.frame"))
    , checkmate::check_class(tp_model, classes = c("character"))
    , combine = "or", .var.name = "tp_model"
  )
  if(is.character(tp_model)) assert_directory_exists(tp_model)
  assert_string(output_path, null.ok = TRUE)
  if(!is.null(output_path)) assert_directory_exists(output_path)
  # writing into the input folder would overwrite the transport model files
  if(is.character(tp_model) && !is.null(output_path)){
    same_dir <- normalizePath(c(tp_model[1], output_path), winslash = "/", mustWork = TRUE)
    if(.Platform$OS.type == "windows") same_dir <- tolower(same_dir)
    if(same_dir[1] == same_dir[2]){
      cli::cli_abort(c("{.arg output_path} must differ from the {.arg tp_model} folder."
                       , "x" = "Writing to {.path {output_path}} would overwrite the transport model files.")
                     , class = "gtfs2emis_error")
    }
  }
  
  ## height file ----
  assert_checks(
    checkmate::check_class(heightfile, classes = c("RasterLayer","Raster"),null.ok = TRUE)
    , checkmate::check_class(heightfile, classes = c("character"),null.ok = TRUE)
    , combine = "or", .var.name = "heightfile"
  )
  if(is.character(heightfile)) assert_file_exists(heightfile)
  
  ## i) EF model ----
  assert_choice(ef_model
                           ,c("ef_brazil_cetesb","ef_usa_emfac"
                              ,"ef_usa_moves","ef_europe_emep"
                              ,"ef_brazil_scaled_euro")
                           ,null.ok = FALSE)
  ## process ----
  assert_character(process, any.missing = FALSE, min.len = 1)
  assert_subset(process, c("hot_exhaust", "tyre", "brake", "road"))
  if(any(process != "hot_exhaust") && ef_model != "ef_europe_emep"){
    cli::cli_abort(c("Wear processes ({.val tyre}, {.val brake}, {.val road}) are only available with {.code ef_model = \"ef_europe_emep\"}."
                     , "x" = "{.arg process} is {.val {process}} and {.arg ef_model} is {.val {ef_model}}.")
                   , class = "gtfs2emis_error")
  }
  if("hot_exhaust" %in% process && length(unique(process)) > 1){
    cli::cli_abort(c("{.arg process} cannot mix {.val hot_exhaust} with wear processes."
                     , "i" = "Run {.fn emission_model} once for {.val hot_exhaust} and once for the wear processes.")
                   , class = "gtfs2emis_error")
  }
  ## ii) Fleet data  | EF model ----
  if (ef_model != "ef_europe_emep"){
    assert_checks(
      checkmate::check_choice('veh_type', names(fleet_data))
      , checkmate::check_choice('model_year', names(fleet_data))
      , checkmate::check_choice('fleet_composition', names(fleet_data))
      , combine = "and", .var.name = "fleet_data"
    )
  }
  if (ef_model %in% c("ef_usa_moves","ef_usa_emfac")){
    assert_choice('fuel', names(fleet_data), .var.name = "fleet_data")
  }
  if (ef_model == "ef_brazil_scaled_euro"){
    assert_checks(
      checkmate::check_choice('euro', names(fleet_data))
      , checkmate::check_choice('type_name_eu', names(fleet_data))
      , checkmate::check_choice('fuel', names(fleet_data))
      , checkmate::check_choice('tech', names(fleet_data))
      , combine = "and", .var.name = "fleet_data"
    )
  }
  if (ef_model == "ef_europe_emep"){
    if("hot_exhaust" %in% process){
      assert_checks(
        checkmate::check_choice('veh_type', names(fleet_data))
        , checkmate::check_choice('euro', names(fleet_data))
        , checkmate::check_choice('fuel', names(fleet_data))
        , checkmate::check_choice('tech', names(fleet_data))
        , checkmate::check_choice('fleet_composition', names(fleet_data))
        , combine = "and", .var.name = "fleet_data"
      )
    }else{
      # names fleet_data
      assert_checks(
        checkmate::check_choice('veh_type', names(fleet_data))
        , checkmate::check_choice('fleet_composition', names(fleet_data))
        , combine = "and", .var.name = "fleet_data"
      )
    }
  }
  
  ## iii) Transport model ----
  
  ### Character input path----
  if(is.character(tp_model)){ 
    
    tp_fname_files <- list.files(path = tp_model,pattern = "\\.rds$"
                                 ,all.files = TRUE,full.names = TRUE)
    tp_name_files <- list.files(path = tp_model,pattern = "\\.rds$"
                                ,all.files = TRUE,full.names = FALSE)
    
    # check if there is files with .txt|.rds patterns
    if(length(tp_fname_files) == 0){ 
      cli::cli_abort(c("No {.file .rds} files were found in {.path {tp_model}}."
                       , "i" = "Please provide a valid input path.")
                     , class = "gtfs2emis_error")
    }
    
  }

  # B) EF function ----------------
  
  # Generate EF cetesb_brazil before the loop
  # to avoid multiple runs in the loop
  if(ef_model == "ef_brazil_scaled_euro" | ef_model == "ef_brazil_cetesb"){
    
    if(quiet){
      
      temp_ef <- suppressMessages( ef_brazil_cetesb(pollutant = pollutant,
                                                    veh_type = fleet_data$veh_type,
                                                    model_year = as.numeric(fleet_data$model_year),
                                                    as_list = TRUE) )
    }else{
      
      temp_ef <- ef_brazil_cetesb(pollutant = pollutant,
                                  veh_type = fleet_data$veh_type,
                                  model_year = as.numeric(fleet_data$model_year),
                                  as_list = TRUE) 
    }
    
    if(ef_model == "ef_brazil_scaled_euro"){
      
      temp_local_ef <- temp_ef
      
    }
  }
  
  # C) Emission function -----
  core_fun_emis <- function(temp_shape){ # temp_shape = tp_fname_files[1]
    
    # i) Read GPS linestrings or DT ----
    if (is.character(temp_shape))  temp_shape <- readRDS(temp_shape)
    
    # ii) Get EF  ----
    if (ef_model == "ef_europe_emep" & "hot_exhaust" %in% process) {
      
      if(!is.null(heightfile)){
        temp_shape <- slope_class_europe_emep(tp_model = temp_shape
                                              ,heightfile = heightfile)
        slope_input <- temp_shape$slope_class
      }else{
        slope_input <- 0
      }
      
      temp_ef <- ef_europe_emep(pollutant = pollutant
                                , speed = temp_shape$speed
                                , veh_type = fleet_data$veh_type
                                , tech = fleet_data$tech
                                , fuel = fleet_data$fuel
                                , euro = fleet_data$euro
                                , slope = slope_input
      )
      
    }
    if(ef_model == "ef_usa_emfac"){
      
      temp_ef <- ef_usa_emfac(pollutant = pollutant
                              , reference_year = reference_year
                              , model_year = fleet_data$model_year
                              , speed = temp_shape$speed
                              , fuel = fleet_data$fuel)
    }
    if(ef_model == "ef_usa_moves"){
      
      temp_ef <- ef_usa_moves(pollutant = pollutant
                              , reference_year = reference_year
                              , model_year = fleet_data$model_year
                              , speed = temp_shape$speed
                              , fuel = fleet_data$fuel)
    }
    if(ef_model == "ef_brazil_scaled_euro"){
      
      if(!is.null(heightfile)){
        temp_shape <- slope_class_europe_emep(tp_model = temp_shape
                                              ,heightfile = heightfile)
        slope_input <- temp_shape$slope_class
      }else{
        slope_input <- 0
      }
      
      temp_ef <- ef_scaled_euro(ef_local = temp_local_ef$EF
                                , speed = temp_shape$speed
                                , veh_type = fleet_data$type_name_eu
                                , euro = fleet_data$euro
                                , pollutant = pollutant
                                , fuel = fleet_data$fuel
                                , tech = fleet_data$tech
                                , SDC = 19
                                , slope = slope_input
                                , load = 0.5
                                , fcorr = 1
      )
      
    }
    # iii) Emissions -----
    if("hot_exhaust" %in% process){
      temp_emis <- multiply_ef(fleet_composition = fleet_data$fleet_composition
                               , dist = units::set_units(temp_shape$dist, "km") 
                               , ef = temp_ef
                               , aggregate = FALSE
                               , as_list = TRUE)
    }
    if(ef_model == "ef_europe_emep" & !("hot_exhaust" %in% process)){
      temp_emis <- emi_europe_emep_wear(dist = units::set_units(temp_shape$dist, "km") 
                                        ,speed = units::set_units(temp_shape$speed, "km/h")
                                        ,pollutant = pollutant
                                        ,veh_type = fleet_data$veh_type
                                        ,fleet_composition = fleet_data$fleet_composition
                                        ,load = 0.5
                                        ,process = process
                                        ,as_list = TRUE)
      # remove to add tp_model
      temp_emis$dist <- NULL
      temp_emis$speed <- NULL
      temp_emis$tp_model <- temp_shape
      return(temp_emis)
    }
    # iv) Add data -----
    # Add gps data into emissions
    temp_emis$tp_model <- temp_shape
    
    # Add EF to list
    temp_emis$EF = temp_ef$EF
    # Add fleet info
    temp_emis$fleet_composition <- fleet_data$fleet_composition
    temp_emis$process <- process
    if(ef_model == "ef_brazil_scaled_euro"){
      temp_emis$model_year = fleet_data$model_year
      temp_emis$euro = fleet_data$euro
    }
    if (ef_model != "ef_europe_emep") {
      temp_emis$model_year = fleet_data$model_year
    } else {
      temp_emis$euro = fleet_data$euro
    }
    # v) Save emissions -----
    
    return(temp_emis)
  }
  
  # D) function to write individual files -----
  #if(is.character(tp_model)){ 
  #  p <- progressr::progressor(steps = length(tp_fname_files))
  #}
  
  prepare_emis_output <- function(i){ # i = 1
    #p()
    ###  i) Output Valid ----
    output_name <- paste0(output_path,"/",tp_name_files[i])
    if(continue){ if(file.exists(output_name)) return(NULL)  }
    
    # Core fun
    if(quiet){    
      
      tmp_emis <- suppressMessages(
        core_fun_emis(temp_shape = tp_fname_files[i])
      )
      
    }else{
      
      tmp_emis <- core_fun_emis(temp_shape = tp_fname_files[i])
      
    }
    ###  i) Output NULL ----
    if (is.null(output_path)) {
      return(tmp_emis)
    }
    
    saveRDS(object = tmp_emis,file = output_name)
    return(NULL)
  }
  
  ## E) IF 'tp_model' is character -----
  if(is.character(tp_model)){ 
    
    # parallel processes over the files
    if(ncores > 1){
      oplan <- future::plan("multisession", workers = ncores)
      on.exit(future::plan(oplan), add = TRUE)

      requiredPackages = c("data.table", "sf", "units")
      emisLine <- furrr::future_map(.x = 1:length(tp_fname_files)
                                    ,.f = prepare_emis_output
                                    ,.options = furrr::furrr_options(
                                      seed = TRUE,
                                      packages = requiredPackages))
    }else{
      emisLine <- lapply(X = 1:length(tp_fname_files)
                         ,FUN = prepare_emis_output)
    }
    
    # if an output_path is provided, function do not return data
    if (!is.null(output_path)) return(NULL)
    
    return(emisLine)
  }else{ 
    
    ## F) If 'tp_model' is transport model -----
    
    if(quiet){
      tmp_emis <- suppressMessages(core_fun_emis(tp_model))
    }else{
      tmp_emis <- core_fun_emis(tp_model)
    }

    #  Output NULL 
    if (is.null(output_path)) {
      return(tmp_emis)
    }
    # Output valid
    export_path <- paste0(output_path,"/"
                          ,unique(tp_model$shape_id)[1]
                          ,".rds")
    
    if( data.table::uniqueN(tp_model$shape_id) > 1 & !quiet){
      cli::cli_inform("Writing output as {.file {export_path}} file.")
    }
    
    # continue condition
    if(continue){ if(file.exists(export_path)) return(NULL)  }
    
    saveRDS(object = tmp_emis
            ,file = export_path)
    return(NULL)
  }
}