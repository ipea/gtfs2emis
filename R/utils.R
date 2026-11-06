#' @importFrom data.table := .SD .I .GRP %like% setDT
#' @importFrom methods is
NULL

# Globals
utils::globalVariables(c('id', '.'))
utils::globalVariables(c('Euro', 'Fuel', 'Load', 'Pol','Pollutant','time', 'Slope', 'Segment','segment_id',
                         'Technology','tmp_eq'))
utils::globalVariables(c( 'from_stop_id', 'geometry', 'i.geometry', 'shape_id', 'stop_sequence', 'to_stop_id'))
utils::globalVariables(c('ef_europe_emep_db'))
utils::globalVariables(c('ef_usa_moves_db',"fuel_type"))
utils::globalVariables(c("ef_usa_emfac_db"))
utils::globalVariables(c("ef_brazil_cetesb_db","tmp_model_year"))
utils::globalVariables(c('reference_year', 'model_year', 'ef','pollutant'))
utils::globalVariables(c('lkm_inter', 'ratio', 'temp_lkm'))
utils::globalVariables(c('year','i.den','i.s','i.pah','i.cn','i.t95','den_base',
                         'pah_base','cn_base','t95_base','s_base','den_imp','pah_imp',
                         'cn_imp','t95_imp','s_imp',
                         'from_stop_id', 'geometry', 'i.geometry',
                         'shape_id', 'stop_sequence', 'to_stop_id'))
utils::globalVariables(c('mf_bw' ,'mf_rs', 'mf_tw', 'pol', 'veh'))
utils::globalVariables(c("road_segment","timestamp"))
# slope_class_europe_emep
utils::globalVariables(c('.N','from_height','from_timestamp',
                         'route_type','to_height','to_timestamp',
                         'trip_id','trip_number','raster_cur'))
# emission_model / transport_model
utils::globalVariables(c("arrival_time", "cumdist", "cumtime", "departure_time",
                         "dist", "files_gps_names","speed","rm_path","rm_adj_path"))
# retime_segments (transport_model)
utils::globalVariables(c("cs", "cs_prev", "delta"))
