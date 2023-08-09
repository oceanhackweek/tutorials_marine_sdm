#Creating dataframe of species locations from Arabian Sea/Bay of Bengal from green_turtles.csv file
#Still haven't identified a way to determine if location is on land or sea yet

#Reading in green_turtles
green_turtles<-read.csv("data/raw-bio/green_turtles.csv")
latlong<-as.data.frame(green_turtles[,c("longitude", "latitude", "date_max")]) #extracting lat/long values & day
str(latlong)

#Area of Arabian Sea & Bay of Bengal (International Hydrologic Org. boundaries)
#Arabian Sea: lat -0.7034-25.5974, long 51.0223-74.335
#Bay of Bengal: lat 5.734-24.3777, long 78.8982-95.0488
#Area for both: lat -0.7034-25.5972, long 51.0223-95.0488
max_lat<-25.5972
max_long<-95.0488
min_lat<--0.7043
min_long<-51.0223
geographic_extent<-(x=c(min_long, max_long, min_lat, max_lat))

latlong<-latlong[latlong$longitude>=51.0223 & latlong$longitude<=95.0488,] #limiting long to geographic area of interest
latlong<-latlong[latlong$latitude>=-0.7043 & latlong$latitude<=25.5972,] #limiting lat to geographic area of interest

#Plotting data on map:
library(geodata)
world_map<-world(resolution=3, path="individual-folders/Mary") #downloading world map data
my_map<-raster::crop(x=world_map, y=geographic_extent) #cropping map data to match geographic area                                                 
plot(my_map, axes=T, col="grey95") #plotting map area
points(x=latlong$longitude, y=latlong$latitude) #adding data points

