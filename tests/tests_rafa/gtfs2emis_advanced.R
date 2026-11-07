## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>")

## ---- eval = TRUE, message = FALSE, echo = FALSE------------------------------
devtools::load_all()

## ---- eval = FALSE, message = FALSE-------------------------------------------
#  # From CRAN
#  install.packages("gtfs2emis")
#  
#  # Dev. version with latest features
#  utils::remove.packages('gtfs2emis')
#  devtools::install_github("ipea/gtfs2emis")
#  

## ---- eval = TRUE, message = FALSE--------------------------------------------
library(gtfs2gps)
library(data.table)
library(devtools)
library(sf)
library(units)
library(magrittr)
library(ggplot2)

