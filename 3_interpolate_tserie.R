library(raster)
 
rasterOptions(tmpdir="/media/nrbv3/Data/Modis_MX/temp_raster")
profile<-c("COMPRESS=JPEG,PROFILE=GeoTIFF,TILED=YES,PHOTOMETRIC=YCBCR")
ptm <- proc.time()
setwd("/media/nrbv3/Data/Modis_MX/NDVI_FILTRADO")
listr <- list.files(,pattern = "*.tif")
s <- stack(listr)
NDVI_I <- calc(s, tinterpolation)
# NDVI_I <- approxNA(s) b 
proc.time() - ptm

