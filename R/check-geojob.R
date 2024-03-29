#'@details check is a method for checking the process status of an active (executed)
#' \linkS4class{geojob} object. The method returns \code{process}, which is a list containing
#' two fields: \code{status} and \code{URL}. If the \linkS4class{geojob} object has not been executed
#' (see \code{\link{start}}), this method returns \code{status}='none' and \code{URL}=NULL.
#'
#'@param .Object a \linkS4class{geojob} object with an active GDP process request, 
#' or a \code{character} URL of an existing job
#'@return \code{process}, a list containing
#' \code{status} and \code{URL}. 
#'
#'@description Check status of processing request
#'@title Check status of processing request
#'@aliases check
#'@author Jordan S. Read
#'@seealso \code{\link{start}}
#'@importFrom httr http_error
#'@rdname check-geojob
#'@examples 
#'gj <- geojob() # create geojob object
#'check(gj) # no process for empty geojob object
#'@export            
setGeneric(name="check",def=function(.Object){standardGeneric("check")})

#'@rdname check-geojob
#'@aliases check
setMethod(f = "check",signature(.Object = "geojob"), definition = function(.Object){
	process	<-	list(status=NULL,URL=NULL)
	if (id(.Object) == "<no active job>"){
		process$status <- 'none'
		process$statusType <- 'none'
		process$percentComplete <- 'none'
    return(process)
	} else if (!is.geojobID(id(.Object))) {
	  stop(id(.Object), ' is not a valid geojob ID. Status cannot be checked', call. = FALSE)
	}

	checkForComplete = tryCatch({
    resp <- gGET(url = id(.Object))
    if (httr::http_error(resp)) {
      stop('bad response from server', call. = FALSE)
    }
    resp
    },error = function(e) {
      return(NULL)
      }
    )
  if (is.null(checkForComplete)){
    process$status <- 'unknown'
    process$statusType <- 'unknown'
    process$percentComplete <- 'unknown'
  }
	if (is.null(process$status)){
		checkForCompleteResponse <- gcontent(checkForComplete)
		checkResponseNS <- xml2::xml_ns(checkForCompleteResponse) 
		root <- xml2::xml_root(checkForCompleteResponse)
		status <- xml2::xml_find_all(root,xpath = "//wps:Status", ns = checkResponseNS)
		process$status <- xml2::xml_text(status)
		process$statusType <- xml2::xml_name(xml2::xml_child(status))
		
		if (process$status == "Process successful"){
			root <- xml2::xml_root(checkForCompleteResponse)
			process$percentComplete <- "100"
			process$URL <- xml2::xml_text(xml2::xml_find_all(root, "//@href", ns = checkResponseNS)[[1]])
		} else if (process$status == ""){
		  process$status <- "ProcessStarted"
		} else if (substr(process$status, 1, 34) == "org.n52.wps.server.ExceptionReport"){
		  process$status <- "ProcessFailed"
		} else if (process$status == "Process Started") {
		  process$percentCompleted <- xml2::xml_attr(xml2::xml_find_all(root, "//wps:ProcessStarted"), "percentCompleted", ns = checkResponseNS)
		}
	}
  
  setJobState(process$status)
	return(process)
})

#'@rdname check-geojob
#'@aliases check
setMethod(f = "check",signature(.Object = "character"), definition = function(.Object){
  check(geojob(id = .Object))
})

#' @title Convenience function for GDP process state
#' @rdname successful-methods
#' @aliases
#' successful
#' running
#' error
#' @usage
#' successful(.Object, retry)
#' error(.Object, retry)
#' running(.Object, retry)
#'
#' @param .Object a \linkS4class{geojob} object or geojob ID (character)
#' @param retry logical, attempt to retry again if communication failed with the server
#' @return TRUE/FALSE indicating if process is in the given state (error, processing, successful)
#' @description Simple wrapper to check process status
#'
#' @author Luke Winslow, Jordan S Read
#' @seealso \code{\link{check}}
#'
#' @examples
#' \dontrun{
#' job <- geoknife(stencil = c(-89,42), fabric = 'prism')
#' check(job)
#'
#' running(job)
#' error(job)
#' successful(job)
#' }
#'
#' @export
successful <- function(.Object, retry = FALSE){
  status_is(id(.Object), status = 'successful', retry = retry)
}

#' @rdname successful-methods
#' @aliases running
#' @export
running <- function(.Object, retry = FALSE){
  status_is(id(.Object), status = 'running', retry = retry)
}

#' @rdname successful-methods
#' @aliases error
#' @export
error <- function(.Object, retry = FALSE){
  status_is(id(.Object), status = 'error', retry = retry)
}

status_is <- function(jobID, status, retry){
  
  process = check(jobID)
  if (process$status == 'unknown' && retry){
    Sys.sleep(gconfig('sleep.time'))
    process = check(jobID)
  }
  state <- process$statusType
  switch(status, 
         error = state == "ProcessFailed",
         running = state == "ProcessStarted" | state == "ProcessAccepted",
         successful = state == "ProcessSucceeded")
}
