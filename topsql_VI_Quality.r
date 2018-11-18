query<-"CREATE TABLE IF NOT EXISTS modis.VI_Quality (
id serial NOT NULL PRIMARY KEY,
rid         int not null,
fdate         date not null,
rast        raster
);
DELETE FROM modis.VI_Quality;"
sqldf(query,connection=con)

setwd(rasters)
fls<-dir(rasters,pattern="*VI_Quality_MX.tif$")
#fls<-dir(rasters,pattern="*VI_Quality.tif$")
yrs<-substring(fls,1,4)
for(i in unique(yrs)){
  query<-paste("create table IF NOT EXISTS VI_Quality_",i,"(CHECK (fdate >= DATE '",i,"-01-01' AND fdate <= DATE '",i,"-12-31' )) inherits (modis.VI_Quality); DROP INDEX IF EXISTS modis_VI_Quality_",i,"_spindex",sep="")
  print(query)
  dbGetQuery(con,query)
  subfls<-fls[grep(i,fls)]
  for (f in subfls){
    #command<-paste("raster2pgsql -s 4326 -c -I -C -M -F -t 250x250 ",rasters,f," -Y temp|sudo -u postgres psql -d ",baseDatos,sep="")
    command<-paste("raster2pgsql -s 4326 -I -C -x -r -M -F -k -t 250x250 -q ",rasters,f," -Y temp|sudo -u postgres psql -d ",baseDatos,sep="")
    print(command)
    system(command)
    query<-"alter table temp add column fdate date; update temp set fdate = substring(filename,1, 10)::date;"
    print(query)
    sqldf(query,connection=con)
    query<-paste("insert into VI_Quality_",i," (rid,fdate,rast) select rid,fdate,rast from temp; DROP TABLE IF EXISTS temp;",sep="")
    print(query)
    sqldf(query,connection=con)
  }
  query<-paste("CREATE INDEX modis_VI_Quality_",i,"_spindex ON VI_Quality_",i," using gist(st_convexhull(rast));",sep="")
  print(query)
  sqldf(query,connection=con)
}