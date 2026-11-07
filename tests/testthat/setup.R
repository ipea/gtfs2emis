library(gtfstools)

### generate transport models and fleet data for all emission factor models

#### Europe EMEP --------------------------------------------------------------

# GTFS
gtfs_irl_raw <- system.file("extdata/irl_dub_gtfs.zip", package = "gtfs2emis")
gtfs_irl_raw <- gtfstools::read_gtfs(gtfs_irl_raw)
gtfs_irl <- gtfstools::filter_by_shape_id(gtfs_irl_raw, shape_id = "60-123-b12-1.72.O")

# transport model
tp_model_irl <- transport_model(gtfs = gtfs_irl)

# fleet data
fleet_data_europe <- data.frame(  veh_type = c("Ubus Midi <=15 t" 
                                               ,"Ubus Std 15 - 18 t", 
                                               "Ubus Artic >18 t")
                                  , euro = c("III","IV","V")
                                  , fuel = rep("D",3)
                                  , tech = c("-","SCR","SCR")
                                  , fleet_composition = c(0.4,0.5,0.1))


#### Brazil CETESB --------------------------------------------------------------

# GTFS
# gtfs_bra <- system.file("extdata/bra_cur/bra_cur_gtfs.zip", package = "gtfs2emis")
# gtfs_bra <- gtfstools::read_gtfs(gtfs_bra)
# gtfs_bra <- gtfstools::filter_by_time_of_day(gtfs_bra, from = '08:00:00',to = '10:30:00')
# gtfs_bra <- gtfstools::filter_by_shape_id(gtfs_bra, shape_id = "1709")
# 
# length(gtfs_bra$trips$trip_id)
# 
# # transport model
# tp_model_bra <- transport_model(gtfs = gtfs_bra, parallel = TRUE)

# fleet
fleet_data_cetesb <- data.frame(  veh_type = "BUS_URBAN_D"
                                  , model_year = 2010:2019
                                  , fuel = "D"
                                  , fleet_composition = rep(0.1,10))



#### USA Moves and EMFAC --------------------------------------------------------------

# GTFS
# gtfs_usa <- system.file("extdata/usa_det/usa_det_gtfs.zip", package = "gtfs2emis")
# gtfs_usa <- gtfstools::read_gtfs(gtfs_usa)
# gtfs_usa <- gtfstools::filter_by_time_of_day(gtfs_usa, from = '08:00:00',to = '10:30:00')
# gtfs_usa <- gtfstools::filter_by_shape_id(gtfs_usa, shape_id = "53150")
# 
# length(gtfs_usa$trips$trip_id)
# 
# # transport model
# tp_model_usa <- transport_model(gtfs = gtfs_usa, parallel = TRUE)

# Fleet USA (MOVES | EMFAC)
fleet_data_usa <- data.frame(  veh_type = "BUS_URBAN_D"
                               , model_year = 2010:2019
                               , fuel = "D"
                               , reference_year = 2019
                               , fleet_composition = rep(0.1,10))


