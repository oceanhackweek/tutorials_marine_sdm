#Working through maxnet with stars tutorial with the green_sea_turtle lat/long data
#Loading necessary packages
library(maxnet)
library(dplyr)
library(sf)
library(stars)
library(geodata)
library(dismo)


#Need to convert presence points into a spatial 'simple-features' object
obs<-sf::st_as_sf(latlong, coords=c("longitude", "latitude"), crs=4326) #lat long file is green turtles data

#Now getting CMIP environmental data for timeframe of obs data: 1977-2020
path <- tempdir()
recent <- geodata::worldclim_global(var="bio", res=10, path = path) |>
  stars::st_as_stars() |>
  split()
names(recent) <- sprintf("bio%0.2i", seq_len(length(names(recent))))

#Extracting recent climate covariates- THESE CLIMATE VARIABLES ARE ONLY LAND
#NEED TO READ IN DATA FROM SDMPREDICTORS
env_obs <- stars::st_extract(recent, sf::st_coordinates(obs)) |>
  dplyr::as_tibble()

#Points to characterize recent background
poly <- obs |>                                # start with obs
  sf::st_combine() |>                         # combine into a single multipoint
  sf::st_convex_hull() #|>                     # find convex hull
#sf::st_transform(crs = sf::st_crs(5880)) |> # make planar
 # sf::st_buffer(dist = 200000) |>             # buffer by 200000m
  #sf::st_transform(crs = sf::st_crs(4326)) 

plot(poly)


N <- 1200
back <- sf::st_sample(poly, N)

env_back <- stars::st_extract(recent, sf::st_coordinates(back)) |>
  dplyr::as_tibble() |>
  na.omit()
env_back

col <- sf.colors(categorical = TRUE)
bb <- sf::st_bbox(poly)
plot(recent[1] |> sf::st_crop(bb), 
     main = "", axes = TRUE, key.pos = NULL, reset = FALSE)
maps::map('world', add = TRUE, lwd = 2)
plot(sf::st_geometry(obs), col = col[4], pch = 16, add = TRUE)
plot(sf::st_geometry(poly), add = TRUE, border = col[5], lwd = 2)
plot(back, add = TRUE, col = col[8], pch = ".")

#Below not working- issues w the environmental variable lengths
pres <- c(rep(1, nrow(hm2)), rep(0, nrow(env_back)))
model <- maxnet::maxnet(pres,
                        dplyr::bind_rows(hm2, env_back))

clamp <- TRUE       # see ?predict.maxnet for details
type <- "cloglog"
preds <- clamp <- TRUE       # see ?predict.maxnet for details
type <- "cloglog"
preds <- predict(model, recent |> sf::st_crop(bb), 
                 clamp = clamp, type = type)
preds <- c(predict(model, recent |> sf::st_crop(bb), 
                   clamp = clamp, type = type),
           predict(model, future_2021 |> sf::st_crop(bb) , 
                   clamp = clamp, type = type),
           predict(model, future_2041 |> sf::st_crop(bb), 
                   clamp = clamp, type = type),
           predict(model, future_2061 |> sf::st_crop(bb), 
                   clamp = clamp, type = type),
           along = list(time=as.Date(c("2001-01-01", 
                                       "2021-01-01", 
                                       "2041-01-01", 
                                       "2061-01-01"))))
preds
