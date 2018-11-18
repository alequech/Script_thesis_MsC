library(raster)
require(bfast)
library(devtools)
#install_github('loicdtx/bfastSpatial')
require(bfastSpatial)
library(rasterVis)
library(rts)


NDVI_SG<-brick("NDVI_SG.grd") *  0.0001


date_NDVI<-readRDS("date.rds")

length(date_NDVI$fdate)


NDVI_SG<-setZ(NDVI_SG,date_NDVI$fdate,name="time")


# valid observations
obs <- countObs(NDVI_SG, as.perc=TRUE)
summary(obs)
plot(obs)

# % NA per pixel
percNA <- 100 - countObs(NDVI_SG, as.perc=TRUE)
plot(percNA, main="percent NA per pixel")
summary(percNA)

#Estadisticas 
meanVI <- summaryBrick(NDVI_SG, fun=mean) # na.rm=FALSE by default
cols <- colorRampPalette(brewer.pal(9,"YlGn"))
levelplot(meanVI,main="NDVI -- Improved Colors \nNEON Harvard Forest Field Site", col.regions=cols)

annualMed <- annualSummary(NDVI_SG, fun=median, na.rm=TRUE)
levelplot(annualMed,main="NDVI -- Improved Colors \nNEON Harvard Forest Field Site", col.regions=cols)


plot(NDVI_SG, 1)
bfm <- bfmPixel(NDVI_SG, start=c(2014, 1), interactive=TRUE)
bfm$cell
#83104
#45999
targcell <- bfm$cell


bfm <- bfmPixel(NDVI_SG, cell=targcell, start=c(2014, 1))
bfm$bfm
class(bfm)
plot(bfm$bfm)


bfm1 <- bfmPixel(NDVI_SG, cell=targcell, start=c(2010, 1), 
                 formula=response~harmon, plot=TRUE)
bfm1$bfm

bfm2 <- bfmPixel(NDVI_SG, cell=targcell, start=c(2007, 1), 
                 formula=response~trend, order=1, plot=TRUE)
bfm2$bfm


bfm3 <- bfmPixel(NDVI_SG, cell=targcell, start=c(2007, 1), 
                 formula=response~trend+harmon, plot=TRUE)
bfm3$bfm



bfm4 <- bfmPixel(NDVI_SG, cell=targcell, start=c(2009, 1), 
                 monend=c(2010, 1), plot=TRUE)

bfm4$bfm

bfm5 <- bfmPixel(NDVI_SG, cell=targcell, start=c(2007, 1), 
                 formula=response ~  trend + harmon, order=2, plot=TRUE)
bfm5$bfm




bfm0 <- bfmSpatial(NDVI_SG, start=c(2007, 1), order=1, mc.cores=6,returnLayers = c("breakpoint", "magnitude", "error"))

plot(bfm0)
change <- raster(bfm0, 1)
months <- changeMonth(change)
monthlabs <- c("jan", "feb", "mar", "apr", "may", "jun", 
               "jul", "aug", "sep", "oct", "nov", "dec")
cols <- rainbow(12)


plot(months, col=cols, breaks=c(1:12), legend=FALSE)
legend("bottomright", legend=monthlabs, cex=0.5, fill=cols, ncol=2)

magn <- raster(bfm0, 2)
magn_bkp <- magn
magn_bkp[is.na(change)] <- NA
op <- par(mfrow=c(1, 2))
plot(magn_bkp, main="Magnitude: breakpoints")
plot(magn, main="Magnitude: all pixels")


bfm09 <- bfmSpatial(NDVI_SG, start=c(2014, 1), monend=c(2010, 1), order=1)
change09
change09 <- raster(bfm09, 1)
magn09 <- raster(bfm09, 2)
magn09[is.na(change09)] <- NA

magn09thresh <- magn09
magn09thresh[magn09 > -0.01] <- NA

op <- par(mfrow=c(1, 2))
plot(magn09, main="magnitude")
plot(magn09thresh, main="magnitude < -0.05")
par(op)
magn09_sieve <- areaSieve(magn09thresh, thresh=62500)
magn09_areasieve <- areaSieve(magn09thresh)

magn09_as_rook <- areaSieve(magn09thresh, directions=4)

op <- par(mfrow=c(2, 2))
plot(magn09thresh, main="magnitude")
plot(magn09_sieve, main="pixel sieve")
plot(magn09_areasieve, main="0.5ha sieve")
plot(magn09_as_rook, main="0.5ha sieve, rook's case")

changeSize_queen <- clumpSize(magn09_areasieve)
changeSize_rook <- clumpSize(magn09_areasieve, directions=4)
op <- par(mfrow=c(1, 2))
plot(changeSize_queen, col=bpy.colors(50), main="Clump size: Queen's case")
plot(changeSize_rook, col=bpy.colors(50), main="Clump size: Rook's case")
########################BFAST#################################################
#targcell <- 45999
a<-NDVI_SG[[1:200]]
datacell<-as.vector(a[targcell])

dates0
ndvi <- bfastts(as.vector(NDVI_SG[targcell]), date_NDVI$fdate, type = c("16-day"))
plot(ndvi)

d1 <- bfastpp(ndvi,stl="both")
d1lm<-lm(response ~ trend + harmon, data = ndvipp)
summary(d1lm)


class(ndvipp)

fit<- bfast(ndvi,h = 0.25, season = "harmonic", max.iter = 1000)
plot(fit)



fit01<- bfast01(ndvi, formula=response~trend, test = "OLS-MOSUM")
plot(fit01)

monitor<-bfastmonitor(ndvi, start=c(2014, 1),formula = response ~ harmon + trend, order = 2, lag = NULL, slag = NULL,
                      history = c("ROC", "BP", "all"),
                      type = "OLS-MOSUM", h = 0.25, end = 10, level = 0.05,
                      hpc = "none", verbose = FALSE, plot = TRUE) 
plot(monitor)


cell_ts <- ndvi_sgTs[targcell]
plot(ndvi_sgTs)


###############################################################################
data(tura)
annualMedtura <- annualSummary(tura, fun=median, na.rm=TRUE)
c<-summaryBrick(tura[[1:7]],fun=median, na.rm=TRUE)
d<-c - annualMedtura[[1]]


plot(annualMedtura)
plot(bfm$bfm) 

data("tura")
obs <- countObs(NDVI_SG)
plot(obs)


r <- raster(ncol=10, nrow=10)
s <- stack(lapply(1:3, function(x) setValues(r, runif(ncell(r)))))
s <- setZ(s, as.Date('2000-1-1') + 0:2,name="time")
s
getZ(s)



start <- as.POSIXct("2012-01-15")
interval <- 60

end <- start + as.difftime(1, units="days")

seq(from=start, by=interval*60, to=end)
 
