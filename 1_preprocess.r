library(stringr)
library(sp)
library(raster)
library(tcltk)
library(proto)
library(gsubfn)
library(DBI)
library(RSQLite)
library(RPostgreSQL)
library(sqldf)
t<-proc.time()
baseDatos<-"modis"
usuario<-"postgres"
passwordBD<-"postgres"
home<-"/media/nrbv3/Data/Modis_MX/"
scripts<-paste(home,"scripts/",sep="")
HDFS<-paste(home,"hdfs",sep="")
rasters<-paste(home,"raster/",sep="")
mascara<-paste(home,"insumos/mask_wgs84.tif",sep="")
profile<-c("COMPRESS=JPEG,PROFILE=GeoTIFF,TILED=YES,PHOTOMETRIC=YCBCR")
topsql_ndvi<-paste(scripts,"topsql_ndvi.r",sep="")
topsql_evi<-paste(scripts,"topsql_evi.r",sep="")
topsql_VI_Quality<-paste(scripts,"topsql_VI_Quality.r",sep="")
topsql_pixel_reliability<-paste(scripts,"topsql_pixel_reliability.r",sep="")
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname=baseDatos,host="localhost",port=5432,user=usuario,password=passwordBD)
query<-"create schema if not EXISTS modis;"
sqldf(query,connection=con)
setwd(HDFS)
f<-function(x)unlist(strsplit(x,"\\."))[2]
fnames<-dir(pattern="*hdf*")
dts<-unlist(lapply(fnames,f))
yrs<-substr(dts,2,5)
datestring<-strptime(paste(yrs, substr(dts,6,8)), format="%Y %j")
lst<-unique(dts)
date_lst<-unique(datestring)
for (i in 1:length(lst)){
  fls<-paste(fnames[dts%in%lst[i]],"\n",sep="")
  outfile<-"temp.hdf"
  print(fls)
  cat(fls,file="temp.txt")
  command<-paste("mrtmosaic -i ",getwd(),"/temp.txt -s '111000000001' -o ",outfile,sep="")
  print(command)
  system(command)
  outfile<-paste(rasters,date_lst[i],".tif",sep="")
  cat("
    INPUT_FILENAME = temp.hdf
    OUTPUT_FILENAME = ",outfile,"
    RESAMPLING_TYPE = NEAREST_NEIGHBOR 
    OUTPUT_PROJECTION_TYPE = GEO 
    DATUM = WGS84 
    ",file="temp.prm")
  system("resample -p temp.prm")
}
mask<-raster(mascara)
setwd(rasters)
list_tif<-list.files(rasters, pattern="*.tif$")
list_tif2 <- list_tif[ !grepl("_MX", list_tif) ]
for (i in list_tif2) {
  rtemp<- raster(i)
  tempr<-crop(rtemp,mask)
  salida<-tempr*mask
  nameraster<-unlist(strsplit(i, ".tif", fixed = TRUE))
  nameoutput <-paste(nameraster,"_MX.tif",sep="")
  x1<-unlist(strsplit(i,substr(i,1,24),fixed = TRUE))
  x2<-unlist(strsplit(x1,".tif", fixed = TRUE))
  if(x2 == "NDVI" || x2 == "EVI"){
    writeRaster(salida,filename=nameoutput, format="GTiff",datatype='INT2S', overwrite=TRUE,  options=profile)  
  }else if(x2 == "VI_Quality"){
    writeRaster(salida,filename=nameoutput, format="GTiff",datatype='INT2U', overwrite=TRUE,  options=profile)
  }else{
    writeRaster(salida,filename=nameoutput, format="GTiff",datatype='INT1U', overwrite=TRUE)
  }
  system(paste("rm -f ",i,sep=""))
  system("rm -rf /tmp/*")
}
setwd(scripts)
source(topsql_ndvi)
source(topsql_evi)
source(topsql_VI_Quality)
source(topsql_pixel_reliability)
dbDisconnect(con)
proc.time()-t
setwd(HDFS)
system("rm -f temp.* resample.*")
system("rm -f /tmp/")