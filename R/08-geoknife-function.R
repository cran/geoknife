
#' geoknife 
#' 
#' Creates the processing job and allows specifying the processing details. 
#' 
#'@param stencil a \code{\link{webgeom}}, \code{\link{simplegeom}}, or any type 
#'that can be coerced into \code{\link{simplegeom}}.
#'@param fabric a dataset. A \code{\link{webdata}} or any type that 
#'can be coerced into \code{\link{webdata}}
#'@param knife (optional) a \code{\link{webprocess}} object
#'@param show.progress logical (optional) display progress bar?
#'@param ... additional arguments passed to \code{new} \code{\link{webprocess}}. 
#'Can also be used to modify the \code{knife} argument, if it is supplied.
#'@return and object of class \linkS4class{geojob}
#'@rdname geoknife-methods
#'@details
#'The \code{stencil} argument is akin to cookie cutter(s), which specify how the dataset is 
#'to be sub-sampled spatially. Supported types are all geometric in nature, be they collections 
#'of points or polygons. Because geoprocessing operations require a non-zero area for \code{stencil}, 
#'if points are used (i.e., the different point collections that can be used in \code{\link{simplegeom}}), 
#'there is a negligible automatic point buffer applied to each point to result in a non-zero area. 
#'
#'Naming of the components of the \code{stencil} will impact the formatting of the result returned by 
#'the geoknife processing job (the \code{\link{geojob}})
#'
#'geoknife will check the class of the stencil argument, and if stencil's class is not
#'\code{\link{webgeom}}, it will attempt to coerce the object into a \code{\link{simplegeom}}. 
#'If no coercion method exists, geoknife will fail. 
#'
#'The \code{fabric} argument is akin to the dough or fabric that will be subset with the \code{stencil} 
#'argument. At present, this is a web-available gridded dataset that meets a variety of formatting restrictions. 
#'Several quick start methods for creating a \code{\link{webdata}} object (only \code{\link{webdata}} or 
#'an type that can be coerced into \code{\link{webdata}} are valid arguments for \code{fabric}).
#'
#'Making concurrent requests to the Geo Data Portal will NOT result in faster overall execution times. 
#'The data backing the system is on high performance storage, but that storage is not meant to support 
#'parallelized random access and can be significantly slower under these conditions.
#'@docType methods
#'@aliases
#'geoknife
#'@examples
#'\dontrun{
#'job <- geoknife(stencil = c(-89,42), fabric = 'prism')
#'check(job)
#'
#'#-- set up geoknife to email user when the process is complete
#'
#' job <- geoknife(webgeom("state::Wisconsin"), fabric = 'prism', email = 'fake.email@@gmail.com')
#' 
#'}
#'@export
geoknife <- function(stencil, fabric, knife = webprocess(...), show.progress = TRUE, ...){
  
  if(is.null(knife)) {
    return(NULL)
  }
  
  knife <- as(knife, Class = "webprocess")
  if (!missing(...)){
    # if ... are specified, pass in additional args through ... to modify. 
    knife <- initialize(knife, ...)
  }
  
  if (!is(stencil, "webgeom")){
    stencil <- tryCatch({
      as(stencil, Class = "simplegeom")
    }, error = function(err) {
      wg <- as(stencil, Class = "webgeom")
      return(wg)
    })
  }
  
  fabric <- as(fabric, Class = "webdata")
  geojob <- geojob()
  xml(geojob) <- XML(stencil, fabric, knife)
  url(geojob) <- url(knife)
  geojob@algorithm.version <- algorithmVersion(knife)
  geojob <- start(geojob)
  if (!is.na(knife@email)) {
    email(geojob, knife)
  }
  
  if (knife@wait){
    wait(geojob, sleep.time = knife@sleep.time, show.progress = show.progress)
  }
  
  return(geojob)
}

#'@importFrom httr content_type_xml
genericExecute <- function(url,requestXML){
  
  response <- gPOST(url,content_type_xml(),
                    body = requestXML)  
  
  return(response)
  
}

parseXMLalgorithms  <-  function(xml){
  
  parentKey <- "wps:Process"
  childKey <- "ows:Identifier"
  titleKey <- "ows:Title"
  
  nodes <- xml2::xml_find_all(xml, sprintf("//%s/%s",parentKey,childKey), 
                              ns = pkg.env$NAMESPACES)
  values  <-  lapply(nodes,xml2::xml_text)
  
  nodes <- xml2::xml_find_all(xml, sprintf("//%s/%s",parentKey,titleKey),
                              ns = pkg.env$NAMESPACES)
  names(values) <- xml2::xml_text(nodes)
  
  return(values)
}

parseXMLgeoms <- function(xml){
  
  parentKey <- "FeatureTypeList"
  childKey <- "FeatureType"
  key="Name"
  # ignore namespaces
  xpath <- sprintf("//*[local-name()='%s']/*[local-name()='%s']/*[local-name()='%s']",parentKey,childKey,key)
  nodes <- xml2::xml_find_all(xml, xpath, ns = pkg.env$NAMESPACES)
  values <- xml2::xml_text(nodes)
  return(values)
}


parseXMLattributes <- function(xml,rm.duplicates = FALSE){
  parentKey  <-  "xsd:element"
  childKey <- "maxOccurs"
  key="name"
  
  nodes <- xml2::xml_find_all(xml,paste(c("//",parentKey,"[@",childKey,"]"),collapse=""))
  # will error if none found
  values <- list()
  for (i in 1:length(nodes)){
    values[[i]] <- xml2::xml_attr(nodes[[i]],key)
  }
  values <- unlist(values[values != "the_geom" & values != ""])
  if (rm.duplicates){
    values = unique(values)
  }
  return(values)
}

parseXMLvalues <- function(xml, key, rm.duplicates = FALSE){
  nodes <- xml2::xml_find_all(xml,paste0("//",key))
  # will error if none found
  values <- xml2::xml_text(nodes)
  if (rm.duplicates){
    values = unique(values)
  }
  return(values)
}
