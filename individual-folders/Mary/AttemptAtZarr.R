#Reading the .zarr file in from python
#First have to create environment in the terminal: conda create -n xarray xarray netcdf4 zarr
#(this loads in a lot of packages)

#Then can set up reticulate:
install.packages("reticulate")
library("reticulate")
use_condaenv("xarray")

#Read in file:
xr=import("xarray")
zarrData<-xr$open_dataset("~/shared/marine-SDMs/INDIAN_OCEAN_025GRID_DAILY.zarr")

#Attempting to make data array a pandas
zarrDataPandas<-zarrData$to_dataframe
library("dplyr")
zarrData_DataFrame <-reticulate::py_to_r(zarrDataPandas)
zarrData_DataFrame

python_code <- "
import pandas as pd

data = {'Name': ['Alice', 'Bob', 'Charlie'],
        'Age': [25, 30, 22]}
df = pd.DataFrame(data)
"
py_run_string(python_code)

df <- py$df %>% as.data.frame()
df

selectedLat<-c(32.0)
selectedLong<-c(42.0)
selectedTime<-c("2021-01-01")
selectedVariable<-"CHL"
zarrCHL<-zarrData$sel(time=selectedTime)["CHL"]
zarrCHL<-zarrData$CHL$sel(latitude=selectedLat, longitude=selectedLong, time=selectedTime)
zarrCHL<-zarrData$CHL

zarrCHL<-py$ds.CHL.stack(z=("time", "lat","lon")).to_pandas().reset_index()
str(zarrData)



#Reading in subset of the .zarr file as a netcdf file
library("ncdf4")
library("raster")
data_subset<-nc_open("/home/jovyan/shared/marine-SDMs/IO_subset.nc")

long<-ncvar_get(data_subset, "lon")
lat<-ncvar_get(data_subset, "lat")
time<-ncvar_get(data_subset, "time")
chl<-ncvar_get(data_subset, "CHL")
dim(chl) #are these the correct dimensions?

fillvalue <- ncatt_get(data_subset, "CHL", "_FillValue")
fillvalue
chl.array[chl.array == fillvalue$value] <- NA
chl.slice <- chl.array[, , 1]
r <- raster(t(chl.slice), xmn=min(long), xmx=max(long), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
plot(r)


wind<-ncvar_get(data_subset, "wind_speed")
fillvalue2<-ncatt_get(data_subset, "wind_speed", "_FillValue")
wind[wind == fillvalue2$value] <- NA
windspeed.slice <- wind[, , 1]
r <- raster(t(windspeed.slice), xmn=min(long), xmx=max(long), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
plot(r)




