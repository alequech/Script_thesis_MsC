library(raster)
library(signal)

f_sgolay<-function(x){
sg <- sgolay(p=3, n = 5)
filter(sg, x)
}
ptm <- proc.time()
NDVI_SG<-calc(NDVI_I,f_sgolay)
writeRaster(NDVI_SG,filename="NDVI_SG.grd", bandorder='BIL', overwrite=TRUE)
proc.time() - ptm



writeRaster(NDVI_SG,filename="NDVI_SG.grd", bandorder='BIL', overwrite=TRUE)
