library(dismo)
library(stars)
dsn = 'ZARR:"/home/shared/marine-SDMs/INDIAN_OCEAN_025GRID_DAILY.zarr"'
#bounds = c(longitude = "lon_bounds", latitude = "lat_bounds")
r = read_mdim(dsn)
r

library(dismo)
library(tidyverse)
library(cmocean)
library(stars)

path <- 'ZARR:"/home/jovyan/shared/marine-SDMs/INDIAN_OCEAN_025GRID_DAILY.zarr"'
#bounds <- c(longitude = "lon_bounds", latitude = "lat_bounds")
read_stars(path)
env.dat <- read_stars(path, bounds = bounds)

a = read_stars("/home/jovyan/shared/marine-SDMs/INDIAN_OCEAN_025GRID_DAILY.zarr")

## Rarr

if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("Rarr")

library(Rarr)