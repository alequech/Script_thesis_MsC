tinterpolation <- function(x) {  
  z <- which(is.na(x))
  nz <- length(z)
  nx <- length(x)
  if (nz > 0 & nz < nx) { 
    x[z] <- spline(x=1:nx, y=x, xout=z, method="natural")$y
  }
  x
}
