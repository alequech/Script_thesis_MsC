library('RPostgreSQL')
library('sqldf')
library('rgdal')
library('raster')
library('gWidgets2')
profile<-c("COMPRESS=JPEG,PROFILE=GeoTIFF,TILED=YES,PHOTOMETRIC=YCBCR")
pw <- "postgres"
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "modis",host = "localhost", port = 5432, user = "postgres", password = "postgres") 
dbListTables(con)
qua <- dbReadTable(con,"qa_values") 
value<-as.vector(qua$value)

first_k_bits <- function(int, k=16, reverse=T) {
  ## https://lpdaac.usgs.gov/products/modis_products_table/mod13q1 TABLE 2:
  ## MOD13Q1 VI Quality: "Bit 0 is the least significant (read bit words right to left)"
  integer_vector <- as.integer(intToBits(int))[1:k]
  if(reverse) integer_vector <- rev(integer_vector)
  return(paste(as.character(integer_vector), collapse=""))
} 
df <- data.frame(bits=sapply(value, function(x) first_k_bits(x, k=16, reverse=T)))
df$value <-qua$value
df$quality <- substring(df$bits, 15, 16)
df$usefulness <- substring(df$bits, 11, 14)
df$mixedcloud <- substring(df$bits,6,6)
df$land_water <- substring(df$bits, 3, 5)
df$shadow <- substring(df$bits, 1, 1)


df$filter<-ifelse(df$quality=="00","1",
                  ifelse(df$quality=="11" ,"0",
                         ifelse( df$usefulness=="0000" | df$usefulness=="0001" | df$usefulness=="0010" | df$usefulness=="0011" | df$usefulness=="0100" | df$usefulness=="0101" | df$usefulness=="0110" | df$usefulness=="0111" ,
                                 ifelse(df$land_water=="001" & df$mixedcloud=="0" & df$shadow=="0","1","3"),"2" ))) 
####Nota: cuadrar el Create View 
d<-length(t$fdate)
statqua<-data.frame(approved=numeric(d),usefulness=numeric(d),mixedcloud=numeric(d),nulll=numeric(d),date=numeric(d), stringsAsFactors=FALSE)

ti<-proc.time()
for ( i in 1:length(t$fdate)) {
  j<-gsub("-","_",t$fdate[i])
  pgNDVI<-paste("PG:dbname='modis' host=localhost user='postgres' password='postgres' port=5432 schema='public' table=","'","ndvi_",j,"'"," mode=2;",sep="")
  dsnNDVI=pgNDVI
  ras <- readGDAL(dsnNDVI)
  NDVI <- raster(ras,1)
  pgQUA<-paste("PG:dbname='modis' host=localhost user='postgres' password='postgres' port=5432 schema='public' table=","'","q_",j,"'"," mode=2;",sep="")
  dsn=pgQUA
  ras2 <- readGDAL(dsn)
  qua.ras <- raster(ras2,1)
  remove(ras2,ras)
  nameoutput <-paste("/media/nrbv3/Data/Modis_MX/NDVI_FILTRADO/",t[i,1],"_NDVIF_MX.tif",sep="")
  val<-unique(qua.ras)
  pixel_reclass<-df[ which( df$value %in% val),c("value","filter")]
  mpixel_reclass<-as.matrix(pixel_reclass)
  qua.rela<-reclassify(qua.ras,mpixel_reclass)
  mask.qua<-reclassify(qua.rela, cbind(2:3, NA))
  quafrec<-as.data.frame(freq(qua.rela))
  statqua[i,1]<-quafrec[1,2]
  statqua[i,2]<-quafrec[2,2]
  statqua[i,3]<-quafrec[3,2]
  statqua[i,4]<-quafrec[4,2]
  statqua[i,5]<-t$fdate[i]
  NDVIfil<- mask.qua * NDVI
  writeRaster(NDVIfil,filename=nameoutput, format="GTiff",datatype='INT2U', overwrite=TRUE,  options=profile)
  system("rm -rf /tmp/*")
}

statqua$date<-as.Date(statqua$date,origin = "1970-01-01")
write.csv(statqua,file="/media/nrbv3/Data/Modis_MX/NDVI_FILTRADO/Informe/filtrado.csv")
dbDisconnect(con)
proc.time()-ti





