library(gtfs2emis)
library(gtfstools)
library(data.table)
library(sf)
library(ggplot2)
library(progressr)



##### test ------------------------





# run transport model
test <- function(gtfs_file){
  
gtfs <- gtfstools::read_gtfs(gtfs_file) 
tp_model <- transport_model(gtfs_data = gtfs,
                           min_speed = 2,
                           max_speed = 80,
                           new_speed = 20,
                           spatial_resolution = 100,
                           parallel = FALSE)
}

cur <- system.file("extdata/bra_cur/bra_cur_gtfs.zip", package = "gtfs2emis")
det <- system.file("extdata/usa_det/usa_det_gtfs.zip", package = "gtfs2emis")
dub <- system.file("extdata/irl_dub/irl_dub_gtfs.zip", package = "gtfs2emis")

a <- system.time( x <- test(gtfs_file = cur ) )
b <- system.time( y <- test(gtfs_file = det ) )
c <- system.time( z <- test(gtfs_file = dub ) )





##### Coverage ------------------------
library(covr)
library(testthat)
Sys.setenv(NOT_CRAN = "true")


# each function separately
a <- covr::function_coverage(fun=gtfs2emis::emission_model, test_file("tests/testthat/test_emission_model.R"))
a

# nocov start

# nocov end

# the whole package
Sys.setenv(NOT_CRAN = "true")
cov <- covr::package_coverage(path = ".", type = "tests")
cov

x <- as.data.frame(cov)
covr::codecov( coverage = cov, token ='xx' )





devtools::document()

### CMD Check ----------------
# Check package errors

# LOCAL
tictoc::tic()
Sys.setenv(NOT_CRAN = "true")
devtools::check(pkg = ".",  cran = FALSE, env_vars = c(NOT_CRAN = "true"))
tictoc::toc()



# CRAN
Sys.setenv(NOT_CRAN = "false")
devtools::check(pkg = ".",  cran = TRUE, env_vars = c(NOT_CRAN = "false"))

devtools::check_win_release(pkg = ".")

# devtools::check_win_oldrelease()
# devtools::check_win_devel()


beepr::beep()



tictoc::tic()
devtools::check(pkg = ".",  cran = TRUE, env_vars = c(NOT_CRAN = "false"))
tictoc::toc()





# build binary -----------------
system("R CMD build . --resave-data") # build tar.gz




### pkgdown: update website ----------------

# Run to build the website
pkgdown::build_site()












utils::remove.packages('gtfs2gps')
devtools::install_github("ipea/gtfs2gps")


library(gtfs2emis)
library(gtfstools)
library(data.table)
library(ggplot2)
library(gtfs2gps)


# path to GTFS.zip file
gtfs_file <- system.file("extdata/irl_dub/irl_dub_gtfs.zip", package = "gtfs2emis")

# read GTFS
gtfs <- gtfstools::read_gtfs(gtfs_file)

# Keep Monday services GTFS
gtfs <- gtfstools::filter_by_weekday(gtfs, 
                                     weekday = c('saturday', 'sunday'), 
                                     keep = FALSE)


# check number of stops in trip_id
id <- "6030.2.60-15B-b12-1.359.O"
gtfs1 <- gtfstools::filter_by_trip_id(gtfs, trip_id =  id )
head(gtfs1$stops)



# check number of stops in shape_id
gtfs2 <- gtfstools::filter_by_shape_id(gtfs, shape_id =  '60-15A-b12-1.358.I' )
head(gtfs2$stop_times)





stops_df <- gtfstools::convert_stops_to_sf(gtfs)

head(gtfs$trips)
head(gtfs$stop_times)
head(gtfs$stops)
head(gtfs$shapes)


gps <- gtfs2gps(gtfs)
gps_sf <- gtfs2gps::gps_as_sflinestring(gps)
# gps_sf <- gtfs2emis::transport_model(gtfs1)

ggplot() +
  geom_sf(data=gps_sf, aes(color=as.numeric(speed))) +
  geom_sf(data=stops_df, color='red') 




mtcars

list(mtcars, mtcars, NULL, mtcars) |> rbindlist()
