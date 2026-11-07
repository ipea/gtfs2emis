# 1) head ----
rm(list=ls())
library(devtools)
library(data.table)
library(magrittr)
library(tictoc)
library(gtfstools)
library(progressr)
library(data.table)
library(ggplot2)
library(units)
library(sf)
library(covr)
#library(mapview)
devtools::install_github("ipea/gtfs2gps")
library(gtfs2gps)
devtools::load_all(".")
#devtools::document(roclets = c('rd', 'collate', 'namespace', 'vignette'))
devtools::document()
devtools::load_all(".")

#devtools::check(vignettes = TRUE)
devtools::check(vignettes = FALSE)
devtools::install()
devtools::check(vignettes = TRUE)
# test vigntte
covr::package_coverage(path = "."
                       ,type = c("vignettes")
                       ,combine_types = TRUE # Default
                       ,quiet = FALSE
)
covr::package_coverage(path = "."
                       ,type = c("tests")
                       ,combine_types = TRUE # Default
                       ,quiet = FALSE
)

covr::package_coverage(path = "."
                       ,type = c("examples")
                       ,combine_types = TRUE # Default
                       ,quiet = FALSE
)

covr::package_coverage(path = "."
                       ,type = c("all")
                       ,combine_types = TRUE # Default
                       ,quiet = FALSE
)

# test
devtools::test_coverage(pkg = ".",show_report = TRUE)
devtools::test(pkg = ".",filter = "ef_scaled_euro")
devtools::test(pkg = ".",filter = "ef_usa")
devtools::test(pkg = ".")

# check
tictoc::tic()
Sys.setenv(NOT_CRAN = "false" )
devtools::check(pkg = "."
                ,  cran = FALSE
                , env_vars = c(NOT_CRAN = "false")
                , vignettes = FALSE
                )
tictoc::toc()
# * transport model ------

#dir.create(path = "tests/test_joao/model")
gtfs_file <- system.file("extdata/irl_dub/irl_dub_gtfs.zip", package = "gtfs2emis")
city_gtfs <- gtfstools::read_gtfs(gtfs_file) #%>% 
  #gtfstools::filter_by_shape_id(c("60-1-b12-1.1.O","60-1-b12-1.2.I"))

gtfs_data <- data.table::copy(city_gtfs)
min_speed = 2
max_speed = 80
new_speed = NULL
parallel = TRUE
spatial_resolution = 100
output_path = NULL


# * emission model ----

tp_model = "tests/test_joao/model/gps_line/"
ef_model = "ef_europe_emep"
fleet_data = data.table::fread(system.file("extdata/irl_dub/irl_dub_fleet.txt"
                                           , package = "gtfs2emis"))
pollutant = "CO2"
parallel = TRUE
output_path = "tests/test_joao/model/emis/"
dir.create(output_path)
reference_year = 2020
emission_model(tp_model = "tests/test_joao/model/gps_line/"
               ,ef_model = "ef_europe_emep"
               ,fleet_data = fleet_data
               ,pollutant = "PM10"
               ,output_path = "tests/test_joao/model/emis/")
emi <-emission_model(tp_model = "tests/test_joao/model/gps_line/"
                     ,ef_model = "ef_europe_emep"
                     ,fleet_data = fleet_data
                     ,pollutant = "PM10") 

# Basic function----
run_basic <- function(pollutant = "PM10"){
  gtfs_file <- system.file("extdata/bra_cur/bra_cur_gtfs.zip", package = "gtfs2emis")
  gtfs <- gtfstools::read_gtfs(gtfs_file) 
  gtfs_small <- gtfstools::filter_by_trip_id(gtfs, trip_id ="4439292")
  
  # run transport model
  tp_model <- transport_model(gtfs_data = gtfs_small
                              , min_speed = 2
                              , max_speed = 80
                              , new_speed = 20
                              , spatial_resolution = 100
                              , parallel = FALSE)
  # Fleet data, using Brazilian emission model and fleet
  fleet_data_ef_cetesb <- data.frame(veh_type = "BUS_URBAN_D",
                                     model_year = 2010:2019,
                                     fuel = "D",
                                     fleet_composition = rep(0.1,10)
  )
  # Emission model
  emi_list <- emission_model(
    tp_model = tp_model,
    ef_model = "ef_brazil_cetesb",
    fleet_data = fleet_data_ef_cetesb,
    pollutant = pollutant
  )
  return(emi_list)
}
# * emis_summary----
rm(list= ls()[!(ls() %in% "run_basic")])
emi_list <- run_basic()

devtools::load_all()

emi_list$road_segment <- 1:nrow(emi_list$tp_model)
emis_summary(emi_list,by = "time")
emis_summary(emi_list)
emis_summary(emi_list,veh_vars = c("model_year","veh_type"),by = "vehicle")
emis_summary(emi_list,by = "time")
emis_summary(emi_list,segment_vars = "road_segment")

# * emis_grid ----
rm(list= ls()[!(ls() %in% "run_basic")])
emi_list <- run_basic()

grid <- sf::st_make_grid(
  x = emi_list$tp_model
  , crs= 4329
  , cellsize = 0.25 / 200
  , what = "polygons"
  , square = FALSE
)

plot(grid)
plot(st_geometry(emi_list$tp_model), add = TRUE,col = "red")

emis_to_dt(emi_list)
devtools::load_all()
emi_grid <- emis_grid(emi_list = emi_list,
                      grid = grid,
                      time_resolution = 'day'
                      ,quiet = FALSE
                      ,aggregate = TRUE)
emi_grid

mapview(emi_grid["PM10"])+
  mapview(emi_list$tp_model$geometry)

plot(grid)
plot(emi_grid["PM10_2010"],add = TRUE)
plot(st_geometry(emi_list$tp_model), add = TRUE,col = "black")
plot(emi_list$tp_model$geometry, add = TRUE,col = "black")

emi_grid <- emis_grid(emi_list = emi_list,
                      grid = grid,
                      time_resolution = 'hour')
emi_grid <- emis_grid(emi_list = emi_list,
                      grid = grid,
                      time_resolution = 'minute')
emi_list1 <- emis_summary(emi_list = emi_list
             ,segment_vars = "tp_model"
             ,by = )
emi_list1
emi_grid

# * reprex issue 258----
reprex::reprex({
  #' `gtfs2gps::gtfs2gps()` is changing the `arrival_time` and `departure_time` by 
  #' reference, which then changes the input file
  #' 
  #' See reprex below
  library(magrittr)
  gtfs_file <- system.file("extdata/poa.zip", package = "gtfs2gps")
  gtfs <- gtfstools::read_gtfs(gtfs_file) 
  gtfs_small <- gtfstools::filter_by_trip_id(gtfs, trip_id ="T2-1@1#520")
  #' Check `class()` before
  str(gtfs_small$stop_times[,c("arrival_time","departure_time")])
  #' Apply function
  a <- gtfs2gps::gtfs2gps(gtfs_small) %>% 
    gtfs2gps::adjust_speed() %>% 
    gtfs2gps::gps_as_sflinestring()
  #' Check `class()` after
  str(gtfs_small$stop_times[,c("arrival_time","departure_time")])
  #' Notice that the function does note work anymore
  #' when the `gtfs_small` is applied again
  a <- gtfs2gps::gtfs2gps(gtfs_small)
})
# End ----