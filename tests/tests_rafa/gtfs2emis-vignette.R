## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>")

## ---- message = FALSE---------------------------------------------------------
library(data.table)
library(sf)
library(units)
library(magrittr)
library(ggplot2)
library(gtfs2gps)
library(gtfs2emis)
library(gtfstools)

## ---- message = FALSE---------------------------------------------------------
# # From CRAN
# install.packages("gtfs2emis")
# library(gtfs2emis)
# 
# # or use the development version with latest features
# utils::remove.packages('gtfs2emis')
# devtools::install_github("ipea/gtfs2emis")
# library(gtfs2emis)

## ---- message = FALSE---------------------------------------------------------
gtfs <- read_gtfs(system.file("extdata/poa.zip", package = "gtfs2gps")) %>%
  filter_week_days() %>%
  filter_by_shape_id(., "176-1") %>% 
  filter_single_trip()

## ---- message = FALSE---------------------------------------------------------
sf_line <- transport_model(gtfs = gtfs,parallel = TRUE)

## ---- message = FALSE, fig.width=3,fig.height=3-------------------------------
head(sf_line$geometry)
sf_line <- sf::st_as_sf(sf_line)
plot(sf_line["trip_number"])

## ---- message = FALSE---------------------------------------------------------
fleet_data_ef_europe <- data.table::data.table("veh_type" = c("Ubus Midi <=15 t"
                                                              ,"Ubus Std 15 - 18 t"
                                                              ,"Ubus Artic >18 t")
                                               ,"euro" = c("III","IV","V")
                                               ,"fuel" = rep("D",3)
                                               ,"tech" = c("-","SCR","SCR")
                                               ,"fleet_composition" = c(0.4,0.5,0.1))
fleet_data_ef_europe

## ---- message = FALSE---------------------------------------------------------
fleet_data_ef_emfac <- data.table::data.table("veh_type" = "BUS_URBAN_D"
                                              ,"model_year" = 2011:2015
                                              ,"fuel" = "D"
                                              ,"calendar_year" = 2019
                                              ,"fleet_composition" = rep(0.2,5))
fleet_data_ef_emfac

## ---- message = FALSE---------------------------------------------------------
fleet_data_ef_moves <- data.table::data.table("veh_type" = "BUS_URBAN_D"
                                              ,"model_year" = 2011:2015
                                              ,"fuel" = "D"
                                              ,"calendar_year" = 2016
                                              ,"fleet_composition" = rep(0.2,5))
fleet_data_ef_moves

## ---- message = FALSE---------------------------------------------------------
fleet_data_ef_cetesb <- data.table::data.table("veh_type" = c("BUS_MICRO_D"
                                                              ,"BUS_URBAN_D"
                                                              ,"BUS_ARTIC_D")
                                               ,"model_year" = rep(2010, 3)
                                               ,"fuel" = rep("D", 3)
                                               ,"fleet_composition" = c(0.4, 0.4, 0.2))
fleet_data_ef_cetesb

