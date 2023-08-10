#Attempt at using SDMpredictors datasets (SSTmean & salinity) to run SDM models using maxnet/stars
#with background data pulled from robis

#First half of code pulled directly from maxnet-sdm.Rmd

suppressPackageStartupMessages({
  library(maxnet)
  library(dplyr)
  library(maxnet)
  library(sf)
  library(stars)
  library(geodata)
  library(dismo)
  library(lubridate)
  library(sdmpredictors)
})

#Defining Area of Interest
library(sf)
lats <- c(-0.125, 32.125); lons <- c(41.875, 70.125)
# raster extent is defined by west lon, east lon, south lat, north lat
ext <- raster::extent(lons[1], lons[2], lats[1], lats[2])
extent_polygon <- as(ext, "SpatialPolygons") %>% st_as_sf()
# we need to assign a coordinate system; 4326 is the default for maps in sf
sf::st_crs(extent_polygon)<-4326

library("rnaturalearth")
library("rnaturalearthdata")
world <- ne_countries(scale = "medium", returnclass = "sf")

library(ggplot2)
library(sf)
ggplot(data = world) +
  geom_sf() + 
  geom_sf(data = extent_polygon, color = "red", fill=NA)

#Loading in occurence data
spp <- "Chelonia mydas"
fil <- file.path(here::here(), "data", "raw-bio", "io-sea-turtles.csv")
occ <- read.csv(fil)
occ <- occ %>% subset(scientificName == spp)

library(tidyverse)
colnames(occ)

occ <- occ %>% subset(bathymetry > 0 & 
                        shoredistance > 0 & 
                        coordinateUncertaintyInMeters < 200)
dim(occ)

occ$date <- as.Date(occ$eventDate)
occ.sf <- sf::st_as_sf(occ, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326)

#Plotting occurance data
library(ggplot2)
library("ggspatial")
library("sf")
theme_set(theme_bw())
world <- st_make_valid(world)
world_points <- st_centroid(world)
world_points <- cbind(world, st_coordinates(st_centroid(world$geometry)))

plt <- ggplot(data = world) +
  geom_sf(fill= "antiquewhite") +
  geom_point(data = occ, aes(x=decimalLongitude, y=decimalLatitude), color = "red", size=0.1) +
  annotation_scale(location = "bl", width_hint = 0.5) +
  annotation_north_arrow(location = "bl", which_north = "true", 
                         pad_x = unit(0.15, "in"), pad_y = unit(0.25, "in"),
                         style = north_arrow_fancy_orienteering) +
  coord_sf(xlim = lons, ylim = lats) +
  theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), panel.background = element_rect(fill = "aliceblue"))

sf_use_s2(FALSE)
plt + geom_text(data = world_points, aes(x=X, y=Y, label=name),
                color = "darkblue", size=2, check_overlap = TRUE) +
  xlab("longitude") + ylab("latitude") + 
  ggtitle(spp, subtitle = "occurences since 2000")


###NEW-ISH CODE
#Loading in environmental marine data
datasets <- list_datasets(terrestrial = FALSE, marine = TRUE)
layers <- list_layers(datasets)
#View(layers)
layercodes <- c("BO_sstmean","BO_salinity", "BO_bathymean")
env <- load_layers(layercodes, rasterstack=T)

#Cropping env data to match polygon extent
AreaOfInterest <- raster::crop(env, extent(extent_polygon))
plot(AreaOfInterest) #plots of SST & salinity on area of interest

#Preparing env data for maxnet/stars
env<-stars::st_as_stars(env)
env<-split(env)
#env<-mutate(env, BO_bathymean=log10(abs(BO_bathymean)+.00000001)) #can also mutate the variables,
#but this one doesn't much of a difference
env_obs <- stars::st_extract(env, sf::st_coordinates(occ.sf)) |>
  dplyr::as_tibble()

#Preparing background data using the pts_absence data"
background_data<-read_csv("data/raw-bio/pts_absence.csv")
colnames(background_data)<-c("decimalLongitude", "decimalLatitude")
background_data<-na.omit(background_data)
background_data.sf <- sf::st_as_sf(background_data, 
                                   coords = c("decimalLongitude", "decimalLatitude"),
                                   crs = 4326)
env_back <- stars::st_extract(env, sf::st_coordinates(background_data.sf)) |>
  dplyr::as_tibble() |>
  na.omit()
colnames(env_back)<-c("BO_sstmean", "BO_salinity", "BO_bathymean")

#Trying different background data that is smaller polygon, but still figuring out hwo to only get ocean pts
poly <- occ.sf |>                                # start with obs
  sf::st_combine() |>                         # combine into a single multipoint
  #sf::st_convex_hull() |>                     # find convex hull
  # sf::st_transform(crs = sf::st_crs(9292)) |> # make planar
   sf::st_buffer(dist = 200000) #|>             # buffer by 200000m
  # sf::st_transform(crs = sf::st_crs(4326))    # make spherical

z<-poly[coastline]

#Getting land
library("rnaturalearth")
library("rnaturalearthdata")
sf_use_s2(F)
coastline <- ne_countries(scale = "medium", returnclass = "sf")%>%
  sf::st_simplify()%>%
  sf::st_crop(extent_polygon)%>%
  select(scalerank)
plot(extent_polygon)
plot(coastline)
plot(st_difference(st_union(coastline),st_union(extent_polygon)))

sf_use_s2(T)
N <- 1000
back <- sf::st_sample(poly, N)

env_back <- stars::st_extract(env, sf::st_coordinates(back)) |>
  dplyr::as_tibble() |>
  na.omit()
env_back


##Back to the code:
col <- sf.colors(categorical = TRUE)
bb <- sf::st_bbox(extent_polygon)
plot(env[1] |> sf::st_crop(bb), 
     main = "", axes = TRUE, key.pos = NULL, reset = FALSE)
maps::map('world', add = TRUE, lwd = 2)
plot(sf::st_geometry(occ.sf), col = col[4], pch = 16, add = TRUE)
#plot(sf::st_geometry(extent_polygon), add = TRUE, border = col[5], lwd = 2)
plot(background_data.sf, add = TRUE, col = col[8], pch = ".") #adds background data as points

#Attempting to run model
env_obs<-na.omit(env_obs)
colnames(env_obs)<-c("BO_sstmean", "BO_salinity", "BO_bathymean")

pres <- c(rep(1, nrow(env_obs)), rep(0, nrow(env_back)))

model <- maxnet::maxnet(pres, dplyr::bind_rows(env_obs, env_back))
summary(model) 
plot(model, type = "cloglog")

#Predicting something? not working yet
#devtools::install_github("BigelowLab/maxnet")

clamp <- TRUE       # see ?predict.maxnet for details
type <- "cloglog"
preds <- predict(model, env |> sf::st_crop(bb), 
                   clamp = clamp, type = type)
plot(preds, reset=F)
plot(st_geometry(occ.sf), pch=".", add=T) #adds presence pts
plot(st_geometry(background_data.sf), add=T, col="orange", pch=".") #adds background pts


