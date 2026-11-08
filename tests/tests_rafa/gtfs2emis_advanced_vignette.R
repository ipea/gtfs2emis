## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>")

## ---- eval = FALSE, message = FALSE-------------------------------------------
#  # From CRAN
#  install.packages("gtfs2emis")
#  
#  # or use the development version with latest features
#  utils::remove.packages('gtfs2emis')
#  devtools::install_github("ipea/gtfs2emis")
#  

## ---- message = FALSE---------------------------------------------------------
library(gtfs2emis)
library(gtfstools)
library(gtfs2gps)
library(data.table)
library(sf)
library(units)
library(magrittr)
library(ggplot2)

## ---- message = FALSE---------------------------------------------------------
gtfs <- read_gtfs(system.file("extdata/poa.zip", package = "gtfs2gps")) %>%
  filter_week_days() %>%
  filter_by_shape_id(., "176-1") %>% 
  filter_single_trip()

