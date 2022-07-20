## ----setup, include=FALSE---------------------------------
library(rmarkdown)
options(continue=" ")
options(width=60)
library(knitr)
library(geoknife)
knitr::opts_chunk$set(eval=nzchar(Sys.getenv("geoknife_vignette_eval")))

## ---- warning=FALSE, message=FALSE------------------------
library(geoknife)

## ---- warning=FALSE, message=FALSE------------------------
knife <- webprocess(algorithm = list('OPeNDAP Subset' = "gov.usgs.cida.gdp.wps.algorithm.FeatureCoverageOPeNDAPIntersectionAlgorithm"))

fabric <- webdata(url='https://cida.usgs.gov/thredds/dodsC/ssebopeta/monthly', 
                  variable="et", #Monthly evapotranspiration
                  times=c('2014-07-15','2014-07-15'))

stencil <- simplegeom(data.frame('point1' = c(-76,49), 'point2' = c(-93,40)))
job <- geoknife(stencil, fabric, knife, wait = TRUE, OUTPUT_TYPE = "geotiff")

## ---- warning=FALSE, message=FALSE------------------------
dest <- file.path(tempdir(), 'et_data.zip')

file <- download(job, destination = dest, overwrite = TRUE)

unzip(file, exdir=file.path(tempdir(),'et'))

tiff.dir <- file.path(tempdir(),'et')

## ---- warning=FALSE, message=FALSE------------------------
library(rasterVis)
library(raster)

et <- raster(file.path(tiff.dir , dir(tiff.dir)))
NAvalue(et) <- -1

## ---- warning=FALSE, message=FALSE------------------------
library(ggmap)
library(ggplot2)

gplot(et, maxpixels = 5e5) + 
  geom_tile(aes(fill = value), alpha=1) +
  scale_fill_gradientn("Actual ET (mm)", colours=rev(heat.colors(5))) +
  coord_equal() + 
  theme_classic() + 
  theme(axis.line = element_blank(), axis.text.x = element_blank(), axis.text.y = element_blank(),
        axis.ticks = element_blank(), axis.title.x = element_blank(), axis.title.y = element_blank()) +
  scale_y_continuous(limits=c(et@extent@ymin, et@extent@ymax)) + 
  scale_x_continuous(limits=c(et@extent@xmin, et@extent@xmax))

