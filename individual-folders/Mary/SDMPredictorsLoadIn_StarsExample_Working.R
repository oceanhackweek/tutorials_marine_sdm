#Working through maxnet with stars tutorial with the green_sea_turtle lat/long data
#loading in environmental data from SDMPredictors, running SDM with ZOON, and then
#trying to incorporate environmental data into maxnet/stars SDM


#Loading necessary packages
library(maxnet)
library(dplyr)
library(sf)
library(stars)
library(geodata)
library(dismo)


#ZOON SDM Notes
#Need to convert presence points into a spatial 'simple-features' object
green_turtles<-read.csv("data/raw-bio/green_turtles.csv")
latlong<-as.data.frame(green_turtles[,c("longitude", "latitude", "date_max")]) #extracting lat/long values & day
str(latlong)

lats <- c(-0.125, 32.125) #area of interest
lons <- c(41.875, 65.125)
latlong<-latlong[latlong$longitude>=lons[1] & latlong$longitude<=lons[2],] #limiting long to geographic area of interest
latlong<-latlong[latlong$latitude>=lats[1] & latlong$latitude<=lats[2],]

obs<-sf::st_as_sf(latlong, coords=c("longitude", "latitude"), crs=4326) #lat long file is green turtles data


# Reading in marine environmental variables
install.packages("sdmpredictors")
library(sdmpredictors)
datasets <- list_datasets(terrestrial = FALSE, marine = TRUE)
View(datasets)
layers <- list_layers(datasets)
View(layers)

#Just trying to read in SST mean for now
layercodes <- c("BO_sstmean")
env <- load_layers(layercodes)

#Cropping SST to area of interest
lats <- c(-0.125, 32.125) #area of interest
lons <- c(41.875, 65.125)
# raster extent is defined by west lon, east lon, south lat, north lat
ext <- raster::extent(lons[1], lons[2], lats[1], lats[2])
extent_polygon <- as(ext, "SpatialPolygons") %>% st_as_sf()
sf::st_crs(extent_polygon)<-4326
AreaOfInterest <- raster::crop(env, extent(extent_polygon))
plot(AreaOfInterest) #SST mean for area of interest

library(sdmpredictors)
devtools::install_github("zoonproject/zoon")
library('zoon')
devtools::install_github("lifewatch/marinespeed")
library('marinespeed')

#Getting Turtle Occurence Data File in Correct Format for Zoon SDM:
pointsTurtles <- SpatialPoints(latlong[,c("longitude", "latitude")])
#pointsTurtles <- spTransform(pointsTurtles, CRSobj="+proj=longlat +ellps=GRS80")
occfile <- tempfile(fileext = ".csv")
write.csv(cbind(coordinates(pointsTurtles), value=1), occfile)

workflow(
  occurrence = LocalOccurrenceData(
    occfile, occurrenceType="presence",
    columns = c("longitude", "latitude", "date_max")), 
  covariate = LocalRaster(stack(AreaOfInterest)),
  process = OneHundredBackground(seed = 42),
  model = LogisticRegression,
  output = PrintMap)

#Seeing if turtle locations match predictor map: kind of?
library("ggplot2")
ggplot(data=latlong, aes(x=longitude, y=latitude))+geom_point()

world_map<-world(resolution=3, path="individual-folders/Mary") #downloading world map data
my_map<-raster::crop(x=world_map, y=extent_polygon) #cropping map data to match geographic area                                                 
plot(my_map, axes=T, col="grey95") #plotting map area
points(x=latlong$longitude, y=latlong$latitude) #adding data points


#Trying to use environmental data with maxnet/stars SDM




#STAR STUFF
env<-stars::st_as_stars(env)
env_obs <- stars::st_extract(env, sf::st_coordinates(obs)) |>
  dplyr::as_tibble()
#st_extract doesn't work on stars data

#Points to characterize recent background
poly <- obs |>                                # start with obs
  sf::st_combine() |>                         # combine into a single multipoint
  sf::st_convex_hull() #|>                     # find convex hull
  sf::st_transform(crs = sf::st_crs(5880)) |> # make planar
  sf::st_buffer(dist = 200000) |>             # buffer by 200000m
  sf::st_transform(crs = sf::st_crs(4326)) 

plot(poly)


N <- 1315
back <- sf::st_sample(extent_polygon, N) #just using extent_polygon for now

env_back <- stars::st_extract(env, sf::st_coordinates(back)) |>
  dplyr::as_tibble() |>
  na.omit()
env_back

col <- sf.colors(categorical = TRUE)
bb <- sf::st_bbox(extent_polygon)
plot(env[1] |> sf::st_crop(bb), 
     main = "", axes = TRUE, key.pos = NULL, reset = FALSE)
maps::map('world', add = TRUE, lwd = 2)
plot(sf::st_geometry(obs), col = col[4], pch = 16, add = TRUE)
plot(sf::st_geometry(extent_polygon), add = TRUE, border = col[5], lwd = 2)
plot(back, add = TRUE, col = col[8], pch = ".")

env_obs<-na.omit(env_obs)
pres <- c(rep(1, nrow(env_obs)), rep(0, nrow(env_back)))
model <- maxnet::maxnet(pres,
                        dplyr::bind_rows(env_obs, env_back))

#resp <- plot(model, type = "cloglog", plot = T)

clamp <- TRUE       # see ?predict.maxnet for details
type <- "cloglog"
preds <- predict(model, env |> sf::st_crop(bb), 
                 clamp = clamp, type = type)
