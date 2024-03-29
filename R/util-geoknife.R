#' @importFrom curl curl_version
#' @importFrom utils packageVersion
geoknifeUserAgent <- function() {
  versions <- c(
    libcurl = curl::curl_version()$version,
    `r-curl` = as.character(utils::packageVersion("curl")),
    httr = as.character(utils::packageVersion("httr")),
    geoknife = as.character(utils::packageVersion("geoknife"))
  )
  c(`User-Agent`=paste0(names(versions), "/", versions, collapse = " "))
}
#'@importFrom httr verbose
gverbose <- function(){
  if (gconfig('verbose'))
    httr::verbose()
  else 
    NULL
}

gheaders <- function(){
  httr::add_headers(geoknifeUserAgent())
}

#'@importFrom httr GET add_headers verbose
gGET <- function(url, ...){
  retryVERB(httr::GET, url, ...)
}

#' simple retry for httr VERBs
#' 
#' Useful for intermittent server issues, when a retry will get the job done
#' @param VERB \code{httr} function
#' @param url a url
#' @param \dots additional args passed into VERB
#' @param retries number of times to try before failing
#' @keywords internal
retryVERB <- function(VERB, url, ..., retries = gconfig('retries')){
  response <- simpleError(" ")
  retry <- 0
  while (is(response, 'error') && retry <= retries){
    response <- tryCatch({
      # I don't like doing this, but the GDP response comes back as `content-type`="text/xml" instead of 
      # `content-type`="text/xml; charset=UTF-8" so we get a charset warning message
      suppressWarnings(VERB(url=url, ..., gverbose(), gheaders()))
    }, error=function(e){
      Sys.sleep(gconfig('sleep.time'))
      message('retrying...')
      return(e)
    })
    retry=retry+1
  }
  if (is(response, 'error'))
    stop(response$message, call.=FALSE)
  return(response)
}

#'@importFrom httr POST add_headers
gPOST <- function(url, config = list(), ...){
  retryVERB(httr::POST, url, config=config, ...)
}

#' xml2 version of gcontent
#' 
#' @param response the result of httr::GET(url)
#' @keywords internal
gcontent <- function(response){
  xml2::read_xml(iconv(readBin(response$content, character()), from = "UTF-8", to = "UTF-8"))
}

# takes a web process (knife) and returns a list for use in whisker 
# templating the root element of an execute request.
get_wps_execute_attributes <- function(wp) {
  attribute_list <- list()
  attribute_list["service"] <- "WPS"
  attribute_list["version"] <- version(wp)
  attribute_list["schema_location"] <- paste(c(wp@WPS_NAMESPACE,wp@WPS_SCHEMA_LOCATION),collapse=" ")
  attribute_list["wps"] <- wp@WPS_NAMESPACE
  attribute_list["ows"] <- wp@OWS_NAMESPACE
  attribute_list["ogc"] <- wp@OGC_NAMESPACE
  attribute_list["xlink"] <- wp@XLINK_NAMESPACE
  attribute_list["xsi"] <- wp@XSI_NAMESPACE
  return(attribute_list)
}

algorithmVersion <- function(knife){
  getCaps <- gGET(url(knife), query = list(
    'service' = 'WPS', 'version' = version(knife),'request' = 'DescribeProcess', 
    'identifier'=algorithm(knife)[[1]]))
  doc <- gcontent(getCaps)
  version <- xml2::xml_attrs(xml2::xml_find_all(doc,'//ProcessDescription', 
                                                ns = pkg.env$NAMESPACES)[[1]])[['processVersion']]
  return(version)
}
  