# devtools::install_github("zoonproject/zoon")
# install.packages(sdmpredictors)
library(sdmpredictors)
library(zoon)

# Inspect the available datasets and layers
datasets <- list_datasets(terrestrial = FALSE, marine = TRUE)
View(datasets)
layers <- list_layers(datasets)
View(layers)
# Load equal area rasters and crop with the extent of the Baltic Sea
layercodes <- c("MS_biogeo05_dist_shore_5m", "MS_bathy_5m", 
                "BO_sstrange", "BO_sstmean", "BO_salinity")
env <- load_layers(layercodes, equalarea = TRUE)
australia <- raster::crop(env, extent(106e5,154e5, -52e5, -13e5))
plot(australia)
# Compare statistics between the original and the Australian bathymetry
View(rbind(layer_stats("MS_bathy_5m"),
           calculate_statistics("Bathymetry Australia", 
                                raster(australia, layer = 2))))
# Compare correlations between predictors, globally and for Australia
prettynames <- list(BO_salinity="Salinity", BO_sstmean="SST (mean)", 
                    BO_sstrange="SST (range)", MS_bathy_5m="Bathymetry",
                    MS_biogeo05_dist_shore_5m = "Shore distance")
p1 <- plot_corr(layers_correlation(layercodes), prettynames)
australian_correlations <- pearson_correlation_matrix(australia)
p2 <- plot_correlation(australian_correlations, prettynames)
cowplot::plot_grid(p1, p2, labels=c("A", "B"), ncol = 2, nrow = 1)
print(correlation_groups(australian_correlations))
# Fetch occurrences and prepare for ZOON
occ <- marinespeed::get_occurrences("Dictyota diemensis")
points <- SpatialPoints(occ[,c("longitude", "latitude")],
                        lonlatproj)
points <- spTransform(points, equalareaproj)
occfile <- tempfile(fileext = ".csv")
write.csv(cbind(coordinates(points), value=1), occfile)
# Create SDM with ZOON
workflow(
  occurrence = LocalOccurrenceData(
    occfile, occurrenceType="presence",
    columns = c("longitude", "latitude", "value")), 
  covariate = LocalRaster(stack(australia)),
  process = OneHundredBackground(seed = 42),
  model = LogisticRegression,
  output = PrintMap)
# Layer citations
print(layer_citations(layercodes))